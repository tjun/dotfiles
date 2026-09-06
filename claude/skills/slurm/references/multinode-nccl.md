# マルチノード分散学習 (DDP / torchrun / NCCL) — 詳細

SKILL.md の「マルチノード分散学習」の補足。マルチノード学習ジョブを書く・デバッグする時に読む。
実装例: `apps/planner/models/mochi/scripts/sbatch/stage1-train.sh` (`--nnodes` で multi-node 切替)。

## rendezvous の組み方

`sbatch --nodes=N` でノードを確保し、`srun --ntasks=N --ntasks-per-node=1` で各ノードに
1 タスク起動 → 各タスクが `torchrun --nnodes=N --node_rank=$SLURM_PROCID --rdzv_backend=c10d
--rdzv_endpoint=<master>:<port>` で rendezvous する。master の address は
**ノード間で到達可能な NW の IP** を使う: 専用網があるクラスタ (mdx2 の `vlan.250`) では
ホスト名は mgmt 網 (bond0) に解決され c10d store が不達になるため、master ノードの
その IF の IP (`ip -4 -o addr show $NCCL_SOCKET_IFNAME`) を `--rdzv_endpoint` に渡す。
bond0 で到達できる kgc はホスト名でも可。`GLOO_SOCKET_IFNAME` も同 IF に揃える。

**他ジョブとの共存**: 他者の image build 等が同ノードで CPU を握っていると (例 8 CPU) `--cpus-per-task=64`
の 2node job は `(Resources)` で PENDING する。GPU さえ空いていれば `--cpus-per-task` を 32〜48 に
下げれば共存して起動できる。

**Slurm はノード割当と rendezvous までは面倒を見るが、NCCL のノード間 GPU 通信(transport)は
別レイヤ**で、クラスタ毎に正しい interconnect 設定が要る。`NCCL_DEBUG=INFO` で transport の
選択と失敗理由を必ず確認すること。

## 最重要の落とし穴: RDMA デバイスの露出 (2026-06 実測)

enroot/Pyxis コンテナは既定で **RDMA デバイス (`/dev/infiniband`) を露出しない**。
これが無いと NCCL は `NET/IB : No device found` で TCP socket に fallback し、
2B 級モデルでは comm-bound で**単一ノードより遅くなる** (kgc 実測 2node-TCP 1.0 < 1node 3.4
samples/s)。**`/dev/infiniband` を `--container-mounts`(or `PYXIS_CONTAINER_MOUNTS`)で明示マウント
すると NCCL が `NET/IBext/GDRDMA`(GPU Direct RDMA)を使い高速化** (kgc 実測 2node-IB 5.05
samples/s = 1node 比 ~1.48x / 約32%短縮)。

## クラスタ別の NCCL 設定 (2026-06 実測、kgc/mdx2 とも mlx5 RoCE/IB あり)

| クラスタ | ノード間 NW | 必須 env (最小) | 速度 (kgc 2node 実測) |
|---|---|---|---|
| **kgc** (GB200) | RoCE 4 rail (`roce_rail0-3` / mlx5_2,3,6,7) | **`MELLANOX_VISIBLE_DEVICES=all` + `NCCL_MNNVL_ENABLE=0`** | ✅ 5.3 samples/s = **1node 3.4 の ~1.55x** (4 rail GDRDMA)。実用可 |
| **mdx2** (H200) | 専用 VLAN `vlan.250@bond0` (10.20.0.1/.2) + IB `mlx5_0/1` | `/dev/infiniband` マウント + `NCCL_IB_HCA=mlx5` + `NCCL_SOCKET_IFNAME=vlan.250` + **hosts override (下記)** (`MELLANOX_VISIBLE_DEVICES=all` は使わない) | 学習スループットは未計測 |

- **kgc は `MELLANOX_VISIBLE_DEVICES=all` が正攻法**(enroot mellanox hook が全 rail を露出 → `NET/IBext/GDRDMA`)。`NCCL_DEBUG=INFO` で `NET/IB : Using [0]roce_rail0 ... [N]mlx5_7` と全 rail が並べば OK。
- **mdx2 では `MELLANOX_VISIBLE_DEVICES=all` は不可**: mellanox hook (`99-mellanox.sh`) が `/sys/class/infiniband_mad` を mount しようとして「No such file or directory」でコンテナ起動失敗。代わりに **`/dev/infiniband` を明示マウント + `NCCL_IB_HCA=mlx5`** で NCCL は IB を掴む(`/dev/infiniband` は `stage1-train.sh` が multi-node 時に自動マウント)。

## mdx2 2node: hosts override が必要

torchrun の c10d store は worker をノード**ホスト名 (`hm-gnodeNNN`)** で登録するが、
mdx2 はホスト側 `/etc/hosts` に相手ノードのエントリが無く名前解決できないため、そのままでは
rendezvous が `gai error -3 / IPv6 ... cannot be retrieved` で失敗する
(mdx2-002 には `127.0.1.1 hm-gnode006` という誤エントリまであり、`hm-gnode006` が
loopback に解決される。ホスト側の修正は要 root なので事業者への修正依頼が本筋)。

回避策: 正しい対応 (事業者提供の公式値 `hm-gnode002=10.20.0.1`, `hm-gnode006=10.20.0.2`)
を書いた hosts ファイルをコンテナの `/etc/hosts` に bind mount する:

```bash
# 共有 FS に一度作れば両ノードから見える
cat > /uhome/newmo10/shared/workspaces/vlan-hosts-test/hosts <<EOF
127.0.0.1 localhost
10.20.0.1 hm-gnode002
10.20.0.2 hm-gnode006
EOF

# srun / PYXIS_CONTAINER_MOUNTS に追加
--container-mounts=...,/uhome/newmo10/shared/workspaces/vlan-hosts-test/hosts:/etc/hosts
```

torchrun は `--rdzv_backend=c10d --rdzv_endpoint=10.20.0.1:29400` (master の vlan.250 IP) +
`GLOO_SOCKET_IFNAME=vlan.250` で組む。学習時はさらに `/dev/infiniband` マウント +
`NCCL_IB_HCA=mlx5` + `NCCL_SOCKET_IFNAME=vlan.250` を揃えて `NCCL_DEBUG=INFO` で GDRDMA を確認する。
NCCL の実学習スループットは未計測なので、重い 2node 学習は実測のある kgc が第一候補。

## kgc の MNNVL

GB200 は Multi-Node NVLink を試すが IMEX channel (`/dev/nvidia-caps-imex-channels`)
& `nvidia-imex` daemon がクラスタ未設定のため `MNNVL ... is available but not working ... Set
NCCL_MNNVL_ENABLE=0 to ignore` + `Cuda failure 800 'operation not permitted'` で落ちる。
**`NCCL_MNNVL_ENABLE=0` を必ず付けて RoCE IB に回す**(IMEX が整えば NVLink でさらに速くなるはずだが現状不可)。

## env の伝播と確認

NCCL 環境変数はコンテナへ伝播させる (`srun --container-env=...,NCCL_SOCKET_IFNAME,NCCL_IB_HCA,
NCCL_IB_DISABLE,NCCL_MNNVL_ENABLE,NCCL_DEBUG` に追加、または `PYXIS_CONTAINER_ENV` に追記)。
`NCCL_DEBUG=INFO` で `via NET/IBext/GDRDMA`(=RDMA 成功)か `via NET/Socket`(=TCP fallback=遅い)を必ず確認。
