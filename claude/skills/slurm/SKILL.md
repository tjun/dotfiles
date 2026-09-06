---
name: slurm
description: "GPU クラスタでの Slurm ジョブ投入・管理・sbatch スクリプト作成・コンテナ実行を支援する。「学習を回したい」「GPU で推論」「ジョブを投入」「slurm で実行」といったリクエストや Slurm 関連のトラブルシューティングに使う。"
---

# Slurm ジョブ管理スキル

このプロジェクトの GPU クラスタでは **Slurm + Enroot + Pyxis** でジョブを管理している。

## クラスタ構成と SSH

4 つの独立したクラスタがある。ユーザーがクラスタを指定しない場合は用途とハードウェア要件を聞いて推薦する。

| クラスタ | 投入先 (SSH) | compute ノード (GPU / CPUs / RAM) | アーキ | 用途の目安 |
|---------|-------------|----------------------------------|-------|-----------|
| **lab** | `honajob@amber` (head) | amber (RTX 4080 ×1 / 32 / 91GB), beryl (RTX 5090 ×1 / 8* / 125GB) | x86_64 | 軽量実験・プロトタイピング |
| **gx10** | `honajob@citrine` (head) | citrine, danburite (各 GB10 ×1 / 20 / 119GB) | aarch64 | DGX Spark 環境のテスト |
| **mdx2** | `newmo10@mdx2-002` / `-006` | mdx2-002, mdx2-006 (各 H200 ×4 / 64 / 1TB) | x86_64 | 大規模学習・推論 |
| **kgc** | `honaa@kgc-bcm` (head) | kgc-17, kgc-18 (ssh alias。各 GB200 ×4 / 144 / 1.5TB) | aarch64 | Blackwell 世代 GPU での大規模学習・推論 |

\* beryl の CPU 数は hwloc の誤検出 (24→8) で実際より少なく Slurm に認識されている。

ルール:

- **必ず表の実行ユーザーで SSH する。** 個人ユーザー（例: `newmo02`）だと共有リポジトリ (`/uhome/newmo10/shared/repos/autonomous-driving.git`、他者書込不可) に書き込めず、デフォルトの `slurm-%j.out` も作れない。submit 自体は受理されるがログが残らず「accepted されたのに何も起きない」状態になりがち
- sbatch は head ノードから投げ、実行ノードは `-w <node>` で指定する（beryl / danburite に直接 ssh しても sbatch は通るが、運用は head 経由で統一）
- kgc で `-w` を使う場合は ssh alias ではなく Slurm の正式ノード名 (`kgc-west-z01-gpu01-r05-17`, `-18`) を指定する

**slurm-run の呼び出し方:** 全クラスタで `/usr/local/bin/slurm-run` に配置されている。
ssh 非対話実行では PATH が最小構成になりがちなので、フルパスで指定するのが確実
（head ノードの対話シェルでは `sbatch slurm-run ...` でも動く）。
`sbatch` のオプションとスクリプトの間に `--` は不要。`slurm-run` のオプションと
実行コマンドの間の `--` は必須。

```bash
# OK（mdx2）
ssh newmo10@mdx2-002 "cd /uhome/newmo10/shared/repos/autonomous-driving.git && \
  sbatch --parsable --job-name=<short-id> --gres=gpu:1 /usr/local/bin/slurm-run -b feat/xxx -- <cmd>"

# OK（kgc）— data_paths.conf / 静的マウントは compute ノードに整備済みなので環境変数の明示は不要
ssh kgc-bcm 'sbatch --parsable --job-name=<short-id> --gres=gpu:1 \
  /usr/local/bin/slurm-run -b feat/xxx -- <cmd>'

# NG: ssh mdx2-002（個人ユーザーになる）→ 共有 repo に書けず log が消える
```

## 2 つの利用方法

### A. 個人利用（アドホック実行）

プロトタイピングや一時的な実験用。直接 `srun` / `sbatch` を使う。

```bash
# GPU で即座に実行（フォアグラウンド、SSH 切断で停止）
srun --gres=gpu:1 nvidia-smi

# バッチジョブ（バックグラウンド、SSH 切断しても継続）
sbatch --gres=gpu:1 --wrap="python3 train.py"

# Docker イメージをコンテナで実行
srun --gres=gpu:1 --container-image=nvcr.io/nvidia/pytorch:24.01-py3 \
  python3 -c "import torch; print(torch.cuda.is_available())"

# 特定ノード指定
srun --gres=gpu:1 -w beryl nvidia-smi
```

直接 srun / sbatch では `--gres=gpu:N` を指定しないと GPU は 0（slurm-run 経由はヘッダ指定でデフォルト 1）。
その他は標準の sbatch オプション（`--cpus-per-task`, `--mem`, `-w`, `--time`）を使う。

ad-hoc 実行で `HF_HUB_CACHE` や `$CACHE_ROOT` 等が必要な場合は、先に `data_paths.conf` を
source する（slurm-run 経由なら自動。パスは「共有ディレクトリ」の節を参照）。

**長時間サービス（推論 API 等）を ad-hoc で立てる場合:** `srun` はフォアグラウンドで SSH 切断と共に
死ぬため、head ノードの tmux 内で実行するか `sbatch --wrap` でバックグラウンド化する。
手元のマシンから compute ノード上のサービスへは head ノード経由の SSH ポートフォワードで届く:

```bash
# 手元 → beryl:8000 (推論 API など)
ssh -N -L 8000:beryl:8000 honajob@amber
curl http://localhost:8000/health
```

### B. 共通の仕組み（slurm-run）— 推奨

再現性のあるジョブ実行用。`slurm-run` ラッパーで Git worktree を作成し、指定ブランチのコードで実行する。
CI からも同じ仕組みでジョブを投入する。

> **重要**: slurm-run はリモートブランチを fetch して worktree を作るため、ローカルの
> 未 commit / 未 push の変更はジョブから見えない。新規 sbatch スクリプトやコード変更は
> 投入前に対象ブランチへ commit & push すること。
>
> slurm-run スクリプト自体の `#SBATCH` ヘッダで `--gres=gpu:1` と `--job-name=slurm-run` が
> デフォルト指定されている。GPU 不要なら `--gres=gpu:0` を明示し、`--job-name` は必ず上書きする。

```bash
# ブランチ指定
sbatch slurm-run -b feat/my-feature -- <command...>

# main ブランチ（デフォルト）
sbatch slurm-run -- <command...>

# GPU なし
sbatch --gres=gpu:0 slurm-run -b feat/xxx -- <command...>

# パイプライン（出力ディレクトリ共有）
sbatch --parsable slurm-run -b feat/xxx -p my-pipeline -- <command...>
```

**slurm-run オプション:**

| オプション | 説明 | デフォルト |
|-----------|------|----------|
| `-b BRANCH` | チェックアウトするブランチ | `main` |
| `-p PIPELINE` | パイプライン ID（出力ディレクトリ共有） | `job_<JOB_ID>` |
| `-r REPO_NAME` | リポジトリ名 | `autonomous-driving.git` |

**slurm-run の処理フロー:**
1. `data_paths.conf` 読み込み → 環境変数 export
2. `git fetch --all --prune` → 最新ブランチ取得
3. `git worktree add --detach` → ジョブ用ワークスペース作成
4. 出力ディレクトリ作成
5. `PYXIS_CONTAINER_MOUNTS` に workspace/output の動的マウントを追記、
   `PYXIS_CONTAINER_ENV` を `HF_HUB_CACHE,PIP_CACHE_DIR,UV_CACHE_DIR` で初期化
6. `cd workspace && <command>` 実行
7. EXIT trap で worktree 削除（成功・失敗問わず）

## 共有ディレクトリ

全クラスタで共通のディレクトリ規則がある。**ホームディレクトリにモデルやデータセットをダウンロードしてはいけない。**
パスは `data_paths.conf` で環境変数として定義されている（lab/gx10: `/etc/slurm/data_paths.conf`、
mdx2: `/opt/slurm/etc/data_paths.conf`、kgc: compute ノードの `/etc/slurm/data_paths.conf`）。
slurm-run がジョブ実行時に自動 source するので、通常は環境変数の明示は不要。

> **Note (kgc)**: kgc の `/etc/slurm/data_paths.conf` は ansible (slurm_workspace role) 管理だが、
> BCM の imageupdate で消えることがある。ジョブが `REPO_ROOT` 未定義等で落ちたら ansible の再適用が必要。
> 旧来どおり `sbatch` 実行時に環境変数を明示すれば暫定回避できる。

> **Note**: lab, gx10 はクラスタ内に 2 ノードあるが、共有ストレージはまだ構成されていない。現在は各ノードのローカルディスクに共有ディレクトリを作成して運用している。今後 NFS 等の共有ストレージを導入する予定。
> このため lab/gx10 では: (1) ファイルの確認・配置は実行ノード上で行う（例: `srun -w beryl ls /shared/checkpoints/`）、
> (2) 複数ジョブでデータを受け渡す場合（パイプライン等）は全ジョブを `-w <node>` で同一ノードに固定する。
> kgc は実行 host 側に WEKA 共有ストレージ `/mnt/weka/shared` があり、head node (`kgc-bcm`) からは
> `/mnt/weka` が見えない。ファイル確認・手動配置は `ssh kgc-17` / `ssh kgc-18` で実行 host に入って行う。

### コンテナ内パスとホスト側パス

| 用途 | 環境変数 | コンテナ内 | ホスト (lab/gx10) | ホスト (mdx2) | ホスト (kgc) | マウント |
|------|---------|----------|------------------|--------------|------------|---------|
| リポジトリ | `REPO_ROOT` | - | `/shared/repos` | `/uhome/newmo10/shared/repos` | `/mnt/weka/shared/repos` | - |
| ワークスペース | `WORKTREE_ROOT` | `/workspace` | `/shared/workspaces` | `/uhome/newmo10/shared/workspaces` | `/mnt/weka/shared/workspaces` | 動的 (slurm-run) |
| 出力 | `OUTPUT_ROOT` | `/output` | `/shared/outputs` | `/uhome/newmo10/shared/outputs` | `/mnt/weka/shared/outputs` | 動的 (slurm-run) |
| データセット | `DATASET_ROOT` | `/datasets` | `/shared/datasets` | `/uhome/newmo10/shared/datasets` | `/mnt/weka/shared/datasets` | 静的 (enroot) |
| モデル | `MODEL_ROOT` | `/models` | `/shared/models` | `/uhome/newmo10/shared/models` | `/mnt/weka/shared/models` | 静的 (enroot) |
| チェックポイント | `CHECKPOINT_ROOT` | `/checkpoints` | `/shared/checkpoints` | `/uhome/newmo10/shared/checkpoints` | `/mnt/weka/shared/checkpoints` | 静的 (enroot) |
| キャッシュ | `CACHE_ROOT` | `/cache` | `/shared/cache` | `/uhome/newmo10/shared/cache` | `/mnt/weka/shared/cache` | 静的 (enroot) |

静的マウントは enroot の設定（`/etc/enroot/mounts.d/`）で全コンテナに自動適用される。kgc も整備済み。
動的マウント（workspace, output）は slurm-run 経由の場合のみ自動。個人利用で動的マウントが必要なら
`srun --container-mounts=` で手動指定する。

### データ配置ルール

- **公開モデル**: `$MODEL_ROOT/Qwen/Qwen3-VL-8B-Instruct` (HuggingFace のリポジトリ ID と同じ)
- **公開データセット**: `$DATASET_ROOT/nvidia/PhysicalAI-Autonomous-Vehicles` (同上)
- **チェックポイント**: 学習中の中間状態のみ。完了後は GCS 等にアップロード
- **出力**: `$OUTPUT_ROOT/<job_id>/` や `$OUTPUT_ROOT/<experiment-name>/`
- **キャッシュ**: `HF_HUB_CACHE`, `PIP_CACHE_DIR`, `UV_CACHE_DIR` が `$CACHE_ROOT` 以下に設定済み

## sbatch ジョブスクリプトの書き方

### テンプレート（slurm-run 経由で呼ばれるスクリプト）

ジョブスクリプトは `apps/<app>/scripts/sbatch/` に配置する。以下のパターンに従う：

```bash
#!/bin/bash
# <スクリプトの説明>
#
# slurm-run.sh 経由で呼ばれることを前提とする
#
# Usage:
#   sbatch --job-name=<short-id> slurm-run -b feat/xxx -- \
#     apps/<app>/scripts/sbatch/<script>.sh [--options...]
set -euo pipefail

# --- ホスト上で実行される（制御） ---
# 追加の環境変数設定
export MY_VAR="value"
# コンテナに渡す環境変数を追加
if [ -n "${PYXIS_CONTAINER_ENV:-}" ]; then
  export PYXIS_CONTAINER_ENV="${PYXIS_CONTAINER_ENV},MY_VAR"
else
  export PYXIS_CONTAINER_ENV="MY_VAR"
fi

# --- コンテナ内で実行される（処理） ---
srun --container-image=<image> \
  --container-workdir=/workspace/apps/<app> \
  bash -c '<commands>'
```

### 重要なパターン

**ジョブ名 (`--job-name`) は必ず付ける:**
未指定だと script ファイル名（slurm-run 経由なら `slurm-run`）や `wrap` が job 名になり、
`squeue` / `sacct` で区別できない。script の Usage コメントにも `--job-name=<id>` の例を必ず書く。
命名は `<app>-<task>-<short-suffix>`（例: `planner-train-vlm001`）、`squeue` の表示で切れない 16-24 文字以内が目安。

```bash
sbatch --job-name=planner-train-vlm001 \
       --gres=gpu:4 --cpus-per-task=64 --mem=900G --time=24:00:00 \
       slurm-run -b feat/vlm001 -- apps/planner/scripts/sbatch/train-vlm001.sh
```

**ホスト vs コンテナの役割分離:**
- ホスト上: 環境変数設定、srun 呼び出し（制御のみ）
- コンテナ内: 実処理（学習、推論、ダウンロード等）
- **ホスト環境にライブラリをインストールしてはいけない**

**コンテナイメージの使い方:**
```bash
# リモートイメージ（初回は自動で .sqsh に変換され、時間がかかる）
srun --container-image=nvcr.io/nvidia/pytorch:24.01-py3 ...

# ローカル Docker イメージ → .sqsh 変換
docker build -t my-image -f Dockerfile .
enroot import -o /tmp/my-image.sqsh dockerd://my-image
srun --container-image=/tmp/my-image.sqsh ...

# 事前変換済み .sqsh
srun --container-image=/shared/cache/sqsh/my-image+latest.sqsh ...
```

**PYXIS_CONTAINER_\* と --container-\* の関係:**
`PYXIS_CONTAINER_MOUNTS` / `PYXIS_CONTAINER_ENV` は対応する `--container-mounts` / `--container-env` の
デフォルト値として働き、srun 側でフラグを明示すると環境変数は無視される（pyxis の仕様）。
slurm-run が設定した値を壊さないために、追加したいだけならフラグではなく環境変数に追記する:
```bash
export PYXIS_CONTAINER_ENV="${PYXIS_CONTAINER_ENV},NEW_VAR1,NEW_VAR2"
```
なお enroot 設定による静的マウント（`/datasets` 等）はこの仕組みとは独立で、
`--container-mounts` を明示しても消えない。

### 実験記録 (W&B + GCS + Git + Slurm)

学習・評価系では役割を分ける: **W&B** = 実験台帳（metadata / metrics / lineage。重いファイル本体は上げず GCS URI を external reference Artifact として記録）、**GCS** = 実体の保存（`store-artifact` skill で immutable に保存）、**Git** = コード、**Slurm** = 実行基盤。
すべての Run に `RUN_ID="${STAGE}-${SLURM_JOB_ID}-${GIT_COMMIT:0:8}"` を付け、W&B run name と学習コードの `--run-id` に渡す。

学習・評価・データ前処理の sbatch スクリプトを書く時は
[references/experiment-logging.md](references/experiment-logging.md) を必ず読むこと
（標準 sbatch パターン、W&B に残す metadata、artifact lineage の付け方）。

### Planner 学習用の pre-built image (planner-train / planner-train-mm)

Planner の学習・実験用には **共有の pre-built sqsh** が `$CACHE_ROOT/sqsh/` に置かれている。
ジョブごとに Dockerfile を build せず、これを `--container-image` で直接参照する方が
ビルド時間が無く再現性も高い。

| Image | NGC base | torch / CUDA / Python | 主な用途 |
|-------|----------|----------------------|---------|
| `planner-train` | 26.03 | torch 2.11 / CUDA 13.2 / py3.12 | OpenMMLab 非依存の experiment (dtt, wote 等) |
| `planner-train-mm` | 25.08 | torch 2.8 / CUDA 12.9 / py3.12 | OpenMMLab 依存 (mmcv 2.1.0 / mmengine 0.10.7 / mmdet 3.3.0 / mmsegmentation 1.2.2) |

> mmdet3d は upstream stale (v1.4.0) のため `planner-train-mm` でも意図的に未収録。
> 推論 API 用には別系統の `planner-api-vllm+latest.sqsh` 等がある（起動パターンは
> `apps/simulator/alpasim/scripts/sbatch/lib/api.sh` を参照）。

選び方:

- 既存の planner experiment が mmcv / mmengine / mmdet / mmsegmentation のいずれかに import 依存 → **planner-train-mm**
- それ以外 (純 torch + transformers + deepspeed 等) → **planner-train** (新しい NGC で image 容量も小さい)
- どちらにも無い pkg が必要 → Dockerfile / pyproject.toml を編集して**再 build した sqsh** を使う (host で torch/cuda 系を再 install するのは厳禁。`check_no_base_deps.py` が build 時に検知する)

使い方 (推奨: slurm-run 経由)。`slurm-run` が `data_paths.conf` を source するので `$CACHE_ROOT` がそのまま使え、
`/datasets`, `/models`, `/checkpoints`, `/cache` の静的マウントも自動適用されるため `--container-mounts` の明示は不要:

```bash
#!/bin/bash
# apps/planner/scripts/sbatch/<my-train>.sh
set -euo pipefail

# version は build 結果に合わせて固定する (latest symlink は無い)
IMAGE="${CACHE_ROOT}/sqsh/planner-train-mm.20260420.0.sqsh"

srun --container-image="${IMAGE}" \
     --container-workdir=/workspace \
     python apps/planner/models/experiments/<exp>/train.py --foo bar
```

現行 version の確認方法、image の再 build 手順、slurm-run を使わない場合の使い方は
[references/planner-images.md](references/planner-images.md) を読むこと。

## パイプライン（ジョブチェーン）

`-p PIPELINE_ID` で複数ジョブ間の `/output` を共有し、`--dependency` で実行順序を制御する
（`afterok:` 成功後 / `afterany:` 成否問わず / `afternotok:` 失敗時）。

> **lab/gx10 の注意**: 共有ストレージが無いため、データを受け渡すステップは全て
> `-w <node>` で同一ノードに固定すること。固定しないと前段の出力が後段から見えない。

```bash
BRANCH=feat/my-experiment
PIPELINE=exp-20260403

# ステップ 1: データダウンロード（GPU 不要）
JOB1=$(sbatch --parsable --gres=gpu:0 \
  slurm-run -b $BRANCH -p $PIPELINE -- \
  apps/simulator/alpasim/scripts/sbatch/download-scenes.sh --scene clipgt-xxx)

# ステップ 2: 学習（ステップ 1 成功後）
JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 \
  slurm-run -b $BRANCH -p $PIPELINE -- \
  apps/<app>/scripts/sbatch/train.sh)

# ステップ 3: 評価（ステップ 2 成功後）
sbatch --dependency=afterok:$JOB2 \
  slurm-run -b $BRANCH -p $PIPELINE -- \
  apps/<app>/scripts/sbatch/eval.sh
```

### Pipeline 内の出力レイアウト

`-p PIPELINE_ID` を指定すると slurm-run は次の環境変数をスクリプトに渡す:

| 環境変数 | 値の例 | 用途 |
|---------|-------|------|
| `PIPELINE_ID` | `exp-20260403` | 引き渡された `-p` の値（指定が無ければ `job_<JOB_ID>`） |
| `JOB_OUTPUT_DIR` | `${OUTPUT_ROOT}/exp-20260403` | この pipeline 用の共有 output dir（同じ `-p` の job 間で共有） |

`JOB_OUTPUT_DIR` はホスト側パスで、**ホスト上で動く sbatch スクリプト（制御部）から参照する**。
コンテナ内にはこの環境変数は渡らず、同じディレクトリが `/output` にマウントされるので、
コンテナ内の処理は `/output` を直接使う。

**規約:**
- 各 step は `${JOB_OUTPUT_DIR}/<step-name>-${SLURM_JOB_ID}/` のように **step + job_id を含む subdir** に書く（同じ pipeline 内で衝突回避 + step 識別を両立）
- 後続 step は `${JOB_OUTPUT_DIR}` を ls / glob して前段の出力を探す。job_id を直接知る必要があれば `--dependency` で得た `$JOB1` をスクリプト引数として渡す
- 単発 job (`-p` 無し) なら `PIPELINE_ID` は `job_<JOB_ID>` になり、`JOB_OUTPUT_DIR` も自動的にユニーク。pipeline と単発で同じ書き方が通る

## マルチノード実行

推論 API とシミュレーションを別ノードで実行する場合:

```bash
sbatch --nodes=2 -w amber,beryl slurm-run -b feat/xxx -- \
  apps/simulator/alpasim/scripts/sbatch/pipeline-sim.sh \
  --api-node beryl --sim-node amber \
  --checkpoint /checkpoints/my-model \
  --scene clipgt-xxx
```

### マルチノード分散学習 (DDP / torchrun)

2node 学習の第一候補は **kgc** (`MELLANOX_VISIBLE_DEVICES=all` + `NCCL_MNNVL_ENABLE=0` で
1node 比 ~1.55x 実測)。mdx2 の 2node はコンテナへの hosts override が追加で必要。
RDMA デバイスを掴まないと TCP fallback で単一ノードより遅くなる等の落とし穴が多いので、
マルチノード学習ジョブを書く・デバッグする時は
[references/multinode-nccl.md](references/multinode-nccl.md) を必ず読むこと
（rendezvous の組み方、クラスタ別 NCCL env と hosts override、`NCCL_DEBUG=INFO` での確認方法）。
実装例: `apps/planner/models/mochi/scripts/sbatch/stage1-train.sh` (`--nnodes` で multi-node 切替)。

## ジョブ管理

標準の Slurm コマンド (`sinfo` / `squeue` / `scontrol show job` / `scancel` / `sacct`) を使う。
ログはデフォルトで submit ディレクトリの `slurm-<JOB_ID>.out`。GPU 割当を含む一覧:

```bash
squeue -o "%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %.4C %b"
```

## CI（GitHub Actions）からのジョブ投入

self-hosted runner (gx10 の citrine) 上の `github-runner` ユーザーが
`sudo -u honajob sbatch /usr/local/bin/slurm-run -b <branch> -- <script>` でジョブを投入する。
CI ワークフローを書く・デバッグする時は [references/ci.md](references/ci.md) を読むこと
（構成・処理フロー・workflow yaml の例）。

## 既存の sbatch スクリプト（参照用）

新しいスクリプトを作成する際は、以下の既存スクリプトを先に読んでパターンを確認する:

| スクリプト | 用途 | パス |
|-----------|------|-----|
| download-scenes.sh | HuggingFace からシーンデータをダウンロード | `apps/simulator/alpasim/scripts/sbatch/download-scenes.sh` |
| build-planner-image.sh | planner-train / planner-train-mm の sqsh を build | `apps/planner/scripts/sbatch/build-planner-image.sh` |
| gt-replay.sh | GT Replay シミュレーション実行 | `apps/simulator/alpasim/scripts/sbatch/gt-replay.sh` |
| pipeline-sim.sh | 推論 API + シミュレーション パイプライン | `apps/simulator/alpasim/scripts/sbatch/pipeline-sim.sh` |
| lib/api.sh | API 起動・待機・停止の共通関数 | `apps/simulator/alpasim/scripts/sbatch/lib/api.sh` |
| lib/sim.sh | シミュレーション実行の共通関数 | `apps/simulator/alpasim/scripts/sbatch/lib/sim.sh` |
| test-slurm.sh | slurm-run の動作テスト | `scripts/test-slurm.sh` |

ただし既存スクリプトが本 skill の規約と食い違う場合は規約を優先する（例: `gt-replay.sh` は
出力を `${OUTPUT_ROOT}/gt-replay-<job_id>` と pipeline 共有 dir の**外**に書くため、
後段ステップが `/output` を参照するパイプラインにはそのまま使えない）。
また alpasim 系は `run_sim.py` が内部で docker compose を使うため、コンテナではなく
ホスト上で実処理を実行する例外パターン。

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| GPU が割り当てられない | `--gres=gpu:N` を指定しているか確認（直接 srun/sbatch のデフォルトは 0）。`sinfo` でアイドル GPU も確認 |
| ジョブが `REPO_ROOT` 未定義等で即死する (kgc) | compute ノードの `data_paths.conf` が BCM imageupdate で消えた可能性。ansible (slurm_workspace) 再適用。sbatch 時に環境変数を明示すれば暫定回避可 |
| コンテナ内でファイルが見えない | 静的マウント (`/datasets` 等) は `--container-image` 指定時のみ自動。動的マウント (`/workspace`, `/output`) は slurm-run 経由時のみ（個人利用は `--container-mounts` で手動指定）。`--container-image` なしの srun はホスト実行になる |
| Permission denied | Enroot はホストユーザーの UID で実行される (rootless)。正しい実行ユーザー（クラスタ表参照）で SSH しているか・共有ディレクトリの権限を確認 |
| submit したのにログが出ない | 個人ユーザーで投入している（クラスタ表のルール参照） |
