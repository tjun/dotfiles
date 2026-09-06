---
name: codex-orchestrator
description: |
  Claude を orchestrator、Codex を worker・相談相手として使うための委譲ポリシーと実行手段（codex-cli / codex plugin / agmsg）の使い分けガイド。
  goal 駆動のループで「分解 → 委譲 → 検証 → 再委譲」を完了条件まで回す。
  トリガー: "codexに任せて", "codexに委譲", "codexで並列", "codexをspawn", "codex worker",
  実装・調査タスクを Codex に投げるか検討するとき、複数タスクを fan-out したいとき、
  長時間・対話的な Codex ワーカーを立てたいとき、orchestration を完走させたいとき。
---

# Codex Orchestrator

Claude が計画・タスク分解・レビュー・検証を担い、実装や重い読み込みを Codex に委譲するためのガイド。
Managed Agents の coordinator パターンに倣う: orchestrator は生のコード・ログを大量に読まず、
worker への小さな brief と worker からの蒸留された報告だけをコンテキストに載せる。

**大原則:**

- **Codex は worker であって oracle ではない。** コード変更だけでなく相談・レビューの意見も
  検証対象。根拠を自分で確認できたものだけ採用する
- **並列に write する worker は、実行手段を問わず worker ごとに git worktree / branch で隔離する**
  （read-only の fan-out は共有でよい）。統合は Claude が直列に行い、統合後に全体テストを回す
- 探索ログや大量読みは委譲してよいが、**worker の diff と完了の証拠は Claude 自身が読む**。
  worker の報告は索引であって証拠ではない

## 役割分担

**Claude が持つ（委譲しない）:**

- 設計・API 設計・命名・アーキテクチャ判断
- タスク分解と brief 作成、成果物のレビュー・検証・統合
- 小さな修正（目安 20 行未満。委譲コストの方が高い）。逆にリスクの高い変更は
  行数によらず Claude が持つ
- MCP・シークレットが必要な作業、破壊的操作（push・release・GitHub への mutation）

**Codex に委譲する:**

- 固まった仕様からの実装・リファクタ・機械的な移行
- 再現手順のあるバグ修正、テスト作成、CI 修正、依存更新
- 大規模なコード探索・ログ解析（トークンを大量に読む作業）

## 実行手段の使い分け

| 手段 | 用途 | 状態 |
|---|---|---|
| `codex-cli` skill（`codex exec --sandbox read-only`） | 単発の相談・レビュー・セカンドオピニオン | fresh 開始。session は保存される（残さないなら `--ephemeral`） |
| codex plugin（`codex:codex-rescue` agent） | 使い捨て worker。凍結仕様からの実装、並列 fan-out、background の長時間タスク | fresh 開始。session 保存・resume 可 |
| agmsg spawn | 対話 worker。同じ文脈で複数往復する作業 | コンテキスト維持（プロセス生存中） |

迷ったら plugin。fresh 開始は fan-out ではむしろ利点
（前提の持ち越しがなく、brief だけで再現できる）。
一方向に続きを頼むだけなら agmsg でなく `codex exec resume <session-id>` / `--last` で足りる。
権限は最小から: 調査・レビューは read-only を明示し、write は実装タスクに限る。
brief や一時ファイルにシークレットを書かない。
サブタスクが数十件を超える規模なら「dynamic workflow への載せ替え」（後述）を検討する。

## Orchestration loop（完走の仕組み）

orchestrator の仕事は 1 回の委譲では終わらない。「分解 → 委譲 → 検証 → 再委譲」を
全サブタスクが検証を通るまで回す。

### ループ本体

1. TaskCreate でサブタスクを登録し、worker への割当・検証状態を追跡する
2. 独立なサブタスクはまとめて並列 dispatch する
3. 回収したら必ず検証する（後述「検証」）。再委譲の前に、動いている background job が
   残っていないか `/codex:status` で確かめ、失敗 worker の中途半端な変更は捨てる
   （worktree 分離していればディレクトリごと破棄できる）
4. 失敗は原因で分類してから次の手を選ぶ:
   - transient（timeout・rate limit）→ そのまま再試行
   - brief の不備・仕様の伝達漏れ → **失敗内容と修正指示を brief に追記して再委譲**
     （worker の文脈が有効なら resume、前提から壊れていたら fresh）
   - 権限・環境・外部依存が原因 → ユーザーに報告（worker を替えても解決しない）
   - スコープ外の編集や危険操作をした worker → 1 回で打ち切り
5. 実装起因の失敗が同一サブタスクで 2 回続いたらループから外し、Claude が自分で実装する
6. 全サブタスクが検証を通ったら統合し、全体の完了条件（下記 goal 条件）を最終確認する

### ターンをまたぐ自動継続（/goal）

まとまった orchestration を始めるときは、開始時に検証可能な完了条件を決め、
**ユーザーに `/goal` の設定を提案する**（`/goal` はユーザーコマンドで Claude 自身は
設定できない。コピペできる形で提示する）:

```text
/goal 全サブタスクの変更が統合され、<テストコマンド> が exit 0 で、
git status に想定外の変更がない。または 20 ターンで停止
```

- 条件は「測定可能な終状態 + 証明コマンド + ターン/時間の上限」で書く。
  brief の「完了の証明」をそのまま流用すると orchestration 全体と worker 単位の
  完了基準が一致する
- goal の評価器は会話に現れた出力だけで判定する小型モデルで、完了の**保証**ではない。
  **証明コマンドは状態が変わった節目と最終確認で Claude が実行し、結果を transcript に出す**
  （worker の「やりました」報告では評価が通らないし、通してもいけない）
- ターン上限で止まった場合は達成ではない。何が未達かを明示して報告する

### 待ちが長い作業（/loop）

`--background` の Codex タスクや CI など時間経過でしか進まない待ちが主体になったら、
ユーザーに `/loop <interval> /codex:status` のような定期チェックを提案するか、
ターン内の節目ごとに `/codex:status` で確認して回収する。

## 大規模 fan-out は dynamic workflow に載せ替える

サブタスクが数十件を超える、loop-until-dry（新規発見が尽きるまで探索）や
findings の相互検証が必要——そういう規模では、ターン毎の判断で回すより
Workflow スクリプトに orchestration 自体を固定する方が確実で、再実行もできる。
**ユーザーの明示的なオプトインが必要**（"use a workflow" / `ultracode`）なので、
規模がそれに達したら workflow 化を提案する。

- Claude Code の worker 機構（subagent / workflow の agent）はすべて Claude セッション。
  Codex は各 agent が Bash 経由で `codex exec` を実行する形で参加させる
- 典型パイプライン: discover（Claude が対象を列挙）→ transform（各 item を Codex が
  worktree 内で実装）→ verify（Claude が検証・adversarial review）
- うまくいった run は `.claude/workflows/` に保存して、繰り返す migration や audit の
  コマンドにする

## codex plugin での fan-out（使い捨て worker）

- 単発: Agent tool で `codex:codex-rescue` を起動（デフォルト write。read-only は明示）
- 並列 fan-out: **独立したタスクに限り**、1 メッセージで複数の `codex:codex-rescue` を同時起動
- 長時間タスク: 依頼文に `--background` を含めて起動し、**job ID を task に記録**して
  `/codex:status <job-id>` で確認、`/codex:result <job-id>` で回収する（並列時の取り違え防止）
- 直前の Codex 作業の続き: 依頼文に `--resume` を含める。ただし plugin の `--resume` は
  **リポジトリで最新の完了タスク**を再開する実装なので、fan-out 後は対象がずれ得る。
  複数タスクを流した後は fresh にするか、`codex exec resume <session-id>` で対象を特定する
- レビュー: `/codex:review`、対立視点なら `/codex:adversarial-review`

### Codex 内部の subagent（二段目の fan-out）

Codex 自体にも subagent 機構がある（`~/.codex/agents/` / `.codex/agents/` の TOML 定義。
既定で並列 6 スレッド・ネスト深さ 1、`[agents]` 設定で変更可）。使い分け:

- 大きな**探索・トリアージ・要約**を委譲するときは、Claude 側で N worker に割るより
  1 worker に渡して brief に「必要なら subagent で並列化してよい」と書く方が brief 1 本で済む
- **書き込みタスクは Codex 内部でも並列化させない**（read だけ並列、write は単線が原則）
- 繰り返し使う専門 worker（explorer / reviewer など）は `.codex/agents/` に TOML で定義できる

## agmsg での対話 worker（コンテキスト維持）

**事前起動は不要。** `spawn.sh` がオンデマンドで join → tmux ペイン（または GUI ターミナル）で
Codex を起動し、初回プロンプトで identity 取得とタスク着手まで済ませる。

```bash
~/.agents/skills/agmsg/scripts/spawn.sh codex <name> --project "$(pwd)" \
  --boot-prompt "<最初のタスク>"
```

以後のやりとりは `/agmsg send <name> <message>`、返信は inbox に届く。

### Codex peer の制約

- Codex には Monitor がなく、**idle になった後に送ったメッセージには気づかない**。
  最初のタスクは必ず `--boot-prompt` で渡す。追加依頼は Codex がアクティブなうちに送るか、
  tmux ペインで手動で促す（リアルタイム双方向が必要なら agmsg の codex-monitor ブリッジがあるが beta）
- tmux 内か GUI ターミナルが必要（ヘッドレス環境では spawn できない）
- 終わったら `/agmsg despawn <name>`（応答がなければ `--force`）

### 混線防止ルール（必須）

同一リポジトリで複数の Claude Code セッションが並走しても混ざらないための規約:

1. **1 Claude セッション = 1 ロール。** セッション開始時に作業内容を含む固有名で
   `/agmsg actas <name>` する（例: `claude-authfix`）。デフォルト購読のまま複数セッションを走らせない
2. **1 Codex worker = 1 作業ストリーム。** 名前にタスクを入れ（例: `codex-authfix`）、
   spawn した Claude セッションだけがそこに送る。他のセッションや別タスクと共有しない
   （agmsg のルーティングは正しくても、共有すると Codex 側の会話コンテキストが混濁する）
3. **作業が終わったら despawn** してロールを掃除する

## brief（プロンプト契約）

Codex worker は前回の会話を持たずに始まる（ただし対象リポジトリの AGENTS.md や
`~/.codex/` の設定は読み込まれる）。委譲時は毎回以下を明記する:

- **Goal**: 何を達成するか
- **対象**: リポジトリ・パス・関連ファイル・base（branch / SHA。working tree が dirty なら明記）
- **制約**: 守るべき規約・触ってよいファイル範囲・触ってはいけない箇所
- **Non-goals**: やらないこと（スコープ膨張防止）
- **完了の証明**: 実行すべきテストコマンドと期待結果
- **出力形式**: 変更サマリ・判断根拠など報告してほしい内容
- **詰まったら**: 前提が不明・矛盾なら推測で進めず `BLOCKED: <必要な情報>` と報告して止まる

長い brief は scratchpad の一時ファイルに書いてパスで渡す（インラインで長文を引用しない）。
brief の粒度には最適点がある: worker 1 体あたり固定コストがかかるため、細かく割りすぎると
逆に高くつく。まとまった 1 タスク = 1 worker を基本にする。

## 検証（Claude 必須・省略不可）

1. `git status -sb` と diff で worker の変更を確認する（報告を鵜呑みにしない）
2. brief に書いた「完了の証明」を自分で再現する（テスト実行など）
3. 統合前に `/codex:review` か通常のレビューを通す
4. 相談・レビューで得た**意見**も同じ扱い: 指摘箇所を自分で確認し、根拠を再現できたものだけ
   採用する（反証を試すなら `/codex:adversarial-review` や別 worker）
