# 実験記録 (W&B + GCS + Git + Slurm) — 詳細

SKILL.md の「実験記録」の補足。学習・評価・データ前処理の sbatch スクリプトを書く時に読む。

## 役割分担

| 役割 | 使うもの | 記録する内容 |
|------|----------|--------------|
| 実験台帳・可視化・lineage | W&B | run metadata、metrics、artifact lineage、GCS URI 参照 |
| 重い実体の保存 | GCS | dataset、checkpoint、eval output、可視化、sample、長期保存ログ |
| 再現用のコード | Git | code、config、sbatch script |
| 実行基盤 | Slurm | job id、node、GPU、duration、実行ログ |

W&B には重いファイル本体をアップロードしない。GCS 上の artifact を W&B の external reference
Artifact として記録し、サイズ・checksum・URI などの metadata と lineage を W&B 側で追えるようにする。
GCS へ保存する dataset / checkpoint / eval output / sample / 長期保存ログは `store-artifact` skill を使って
`gs://nm-ad-artifacts-{dev,prod}` に immutable な version として保存する。

## 最小運用ルール

1. すべての学習・評価 Run に `RUN_ID` を付ける
2. dataset / checkpoint / eval output / visualization / sampled media は GCS に置く
3. W&B には GCS URI を external reference Artifact として記録する
4. Slurm job id / git commit / command / config / env vars / node・GPU 情報を W&B に記録する

## Run ID の規約

`RUN_ID` には Slurm job id を必ず含める。形式は次を標準とする:

```bash
RUN_ID="${STAGE}-${SLURM_JOB_ID}-${GIT_COMMIT:0:8}"
```

例: `mochi-v32-stage1-184392-71cb13fa`

この値を W&B run name として使い、学習コードにも `--run-id "$RUN_ID"` のように渡す。
pipeline job では `PIPELINE_ID` と `RUN_ID` を両方残す。`PIPELINE_ID` は複数 step のまとまり、
`RUN_ID` は個々の Slurm job / W&B run の識別子として扱う。

## sbatch script の標準パターン

```bash
#!/bin/bash
#SBATCH --job-name=stage1-waymo
#SBATCH --nodes=2
#SBATCH --gpus-per-node=4
#SBATCH --time=24:00:00
set -euo pipefail

export STAGE=stage1
export GIT_COMMIT="$(git rev-parse HEAD)"
export RUN_ID="${STAGE}-${SLURM_JOB_ID}-${GIT_COMMIT:0:8}"

export WANDB_PROJECT=ad-model-training
export WANDB_ENTITY=<team-or-entity>
export WANDB_NAME="${RUN_ID}"
export WANDB_DIR="/cache/wandb/${RUN_ID}"
export WANDB_ARTIFACT_DIR="/cache/wandb-artifacts/${RUN_ID}"
export OUTPUT_DIR="/output/${RUN_ID}"

WANDB_ENV_VARS="STAGE,GIT_COMMIT,RUN_ID,WANDB_PROJECT,WANDB_ENTITY,WANDB_NAME,WANDB_DIR,WANDB_ARTIFACT_DIR,OUTPUT_DIR"
if [ -n "${PYXIS_CONTAINER_ENV:-}" ]; then
  export PYXIS_CONTAINER_ENV="${PYXIS_CONTAINER_ENV},${WANDB_ENV_VARS}"
else
  export PYXIS_CONTAINER_ENV="${WANDB_ENV_VARS}"
fi

srun --container-image=<image> \
     --container-workdir=/workspace \
     bash -lc 'torchrun \
       --nnodes="${SLURM_NNODES}" \
       --nproc_per_node=4 \
       train.py \
       --config configs/stage1.yaml \
       --run-id "${RUN_ID}" \
       --output-dir "${OUTPUT_DIR}"'
```

`WANDB_DIR` / `WANDB_ARTIFACT_DIR` はコンテナ内の `/cache` 配下に置く。ホームディレクトリへ書かない。
W&B が image に入っていない場合はホストに install せず、project dependency または container image を更新する。

## W&B に必ず残す metadata

- Run metadata: `stage`, `slurm_job_id`, `git_commit`, `command`, `config`, env vars, machine / GPU / node, duration
- Input Artifacts: raw dataset reference, processed dataset reference, input checkpoint reference
- Output Artifacts: output checkpoint reference, eval result reference, visualization / sampled media reference
- Metrics: train loss, val loss, ADE/FDE/RFS, collision rate, offroad rate など task 固有の指標

学習コード側では、GCS に保存済みまたは保存予定の URI を W&B Artifact の external reference として
`use_artifact` / `log_artifact` する。たとえば lineage は次のように追える形にする:

```text
processed dataset
  -> stage1 checkpoint
  -> stage2 checkpoint
  -> evaluation result
```

GCS URI がまだ確定していない一時出力は `/output/${RUN_ID}` に書き、ジョブ完了後に `store-artifact`
skill で GCS に保存してから W&B の artifact reference を更新する。学習コードが直接 GCS に書く場合も、
保存先は `store-artifact` のパス規約 (`latest` / `final` / `best` を version に使わない、既存 prefix を
上書きしない) に合わせる。
