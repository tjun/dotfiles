# Planner pre-built image (planner-train / planner-train-mm) — build と運用の詳細

SKILL.md の「Planner 学習用の pre-built image」の補足。image の選択基準と基本の使い方は SKILL.md 側を参照。

## slurm-run を使わない場合

`data_paths.conf` を手動で source するか、host のフルパスを直書きする。

```bash
source /opt/slurm/etc/data_paths.conf            # mdx2
# source /etc/slurm/data_paths.conf              # lab / gx10 / kgc (compute)
IMAGE="${CACHE_ROOT}/sqsh/planner-train.20260420.0.sqsh"
# もしくは: IMAGE=/uhome/newmo10/shared/cache/sqsh/planner-train.20260420.0.sqsh
```

## sqsh の build (image を更新したい時)

`apps/planner/scripts/sbatch/build-planner-image.sh` を slurm-run 経由で呼ぶ。
Makefile の `release-sqsh` target を実行し、`$CACHE_ROOT/sqsh/<image>.<VERSION>.sqsh` を生成する
(`latest` symlink は作らない)。

```bash
# planner-train を build (mdx2 から。ユーザーは newmo10、ノードは mdx2-002 か mdx2-006)
ssh newmo10@mdx2-002 'sbatch --job-name=planner-img-build --gres=gpu:0 --cpus-per-task=8 --mem=64G --time=02:00:00 \
  /usr/local/bin/slurm-run -b <branch> -- \
  apps/planner/scripts/sbatch/build-planner-image.sh --image planner-train'

# planner-train-mm を build
ssh newmo10@mdx2-002 'sbatch --job-name=planner-imgmm-build --gres=gpu:0 --cpus-per-task=8 --mem=64G --time=02:00:00 \
  /usr/local/bin/slurm-run -b <branch> -- \
  apps/planner/scripts/sbatch/build-planner-image.sh --image planner-train-mm'
```

オプション:
- `--patch N` → 同日再 build 用に PATCH_VERSION を上げる
- `--version YYYYMMDD.N` → VERSION を完全指定

## 現行 version の確認

`latest` symlink は無いので VERSION は明示固定が必要。利用可能な build を確認するには `$CACHE_ROOT/sqsh/` を ls する:

```bash
# mdx2 から
ssh newmo10@mdx2-002 'ls -lh /uhome/newmo10/shared/cache/sqsh | grep planner-train'
```

スクリプトに version を書く時は、この確認結果に合わせて固定する（不明なまま書かない。
ssh で確認できない状況なら `--image-version` 等で上書き可能にしておく）。
