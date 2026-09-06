# CI（GitHub Actions）からのジョブ投入

self-hosted runner (gx10 の citrine) から slurm-run 経由でジョブを投入する。

## 構成

| コンポーネント | 説明 |
|-------------|------|
| **self-hosted runner** | gx10 クラスタの citrine 上で動作。GitHub Actions のジョブを受け取る |
| **runner ユーザー** | `github-runner`。sbatch の投入とログ監視のみ。Docker 権限不要 |
| **ジョブ実行ユーザー** | `honajob` (lab/gx10) / `newmo10` (mdx2)。credential 設定済みの共通ユーザー |
| **sudoers** | `github-runner ALL=(honajob) NOPASSWD: sbatch` (ansible role `github_runner` で自動設定) |

## 処理フロー

```
GitHub Actions (PR / workflow_dispatch)
  ├── self-hosted runner (github-runner) がジョブを受け取る
  ├── sudo -u honajob sbatch slurm-run -b <branch> -- <script>
  │     └── Slurm ジョブ (honajob ユーザー)
  │           ├── slurm-run: worktree 作成、環境変数設定
  │           ├── script: Docker build → enroot import → srun --container-image
  │           └── slurm-run: worktree 削除（cleanup）
  ├── runner: squeue でジョブ完了をポーリング
  ├── runner: tail -f でログをリアルタイム表示
  └── runner: scontrol でジョブの終了コードを確認
```

## ワークフローの例

```yaml
# .github/workflows/example.yml
- name: Submit Slurm job
  run: |
    BRANCH="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME}}"
    JOB_ID=$(sudo -u honajob sbatch --parsable \
      --output="$LOG_DIR/slurm-%j.log" \
      --time=01:00:00 \
      /usr/local/bin/slurm-run -b "$BRANCH" -- \
        apps/<app>/scripts/sbatch/<script>.sh [--options...])
```
