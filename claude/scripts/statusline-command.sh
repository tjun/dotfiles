#!/bin/bash

# Claude Code ステータスライン (3行表示)
# Line1: モデル名 | コンテキスト使用率 | git差分 | ブランチ名
# Line2: 5時間レート制限のプログレスバーとリセット時刻 (Asia/Tokyo)
# Line3: 7日間レート制限のプログレスバーとリセット日時 (Asia/Tokyo)

input=$(cat)

# --- ANSI カラー定義 ---
# 使用率に応じた色: 0-49% 緑, 50-79% 黄, 80-100% 赤
COLOR_GREEN=$'\033[38;2;151;201;195m'   # #97C9C3
COLOR_YELLOW=$'\033[38;2;229;192;123m'  # #E5C07B
COLOR_RED=$'\033[38;2;224;108;117m'     # #E06C75
COLOR_GRAY=$'\033[38;2;140;155;160m'     # #8C9BA0 (セパレータ用)
COLOR_RESET=$'\033[0m'

SEP="${COLOR_GRAY} │ ${COLOR_RESET}"

# 使用率に応じた色を返す関数
usage_color() {
  local pct=$1
  if [ "$pct" -ge 80 ]; then
    printf '%s' "$COLOR_RED"
  elif [ "$pct" -ge 50 ]; then
    printf '%s' "$COLOR_YELLOW"
  else
    printf '%s' "$COLOR_GREEN"
  fi
}

# プログレスバーを生成する関数 (10セグメント, ▰=filled, ▱=empty)
progress_bar() {
  local pct=$1
  local filled=$(( pct * 10 / 100 ))
  local bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then
      bar="${bar}▰"
    else
      bar="${bar}▱"
    fi
  done
  echo -n "$bar"
}

# --- JSON入力からデータを取得 ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
used_pct_raw=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
used_pct=0
[ -n "$used_pct_raw" ] && used_pct=${used_pct_raw%.*}

# --- git情報を取得 ---
branch=""
repo_name=""
diff_added=0
diff_deleted=0
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  repo_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  [ -n "$repo_root" ] && repo_name=$(basename "$repo_root")
  # ステージング済み＋未ステージの変更行数を集計
  diff_stat=$(git -C "$cwd" --no-optional-locks diff --numstat HEAD 2>/dev/null)
  if [ -n "$diff_stat" ]; then
    diff_added=$(echo "$diff_stat" | awk '{sum += $1} END {print sum+0}')
    diff_deleted=$(echo "$diff_stat" | awk '{sum += $2} END {print sum+0}')
  fi
fi

# --- Line 1 の構築 ---
model_color=$(usage_color 0)
ctx_color=$(usage_color "$used_pct")

line1=""

# モデル名
if [ -n "$model" ]; then
  line1="${model_color}🤖 ${model}${COLOR_RESET}"
fi

# コンテキスト使用率
line1="${line1}${SEP}${ctx_color}📊 ${used_pct}%${COLOR_RESET}"

# git差分行数
if [ -n "$branch" ]; then
  line1="${line1}${SEP}${COLOR_GREEN}✏️  +${diff_added}/-${diff_deleted}${COLOR_RESET}"
  line1="${line1}${SEP}${COLOR_GRAY}🔀 ${repo_name}:${branch}${COLOR_RESET}"
fi

# --- レート制限データの取得 (キャッシュあり) ---
CACHE_FILE="/tmp/claude-usage-cache.json"
CACHE_TTL=360  # 秒

five_hour_pct=0
seven_day_pct=0
five_hour_reset=""
seven_day_reset=""

fetch_usage() {
  # macOS キーチェーンから OAuth トークンを取得
  local token
  token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
  if [ -z "$token" ]; then
    return 1
  fi

  # キーチェーンのJSON構造からOAuthトークンを抽出
  local access_token
  access_token=$(echo "$token" | jq -r '.claudeAiOauth.accessToken // .access_token // empty' 2>/dev/null)
  if [ -z "$access_token" ]; then
    access_token="$token"
  fi

  local response
  response=$(curl -sf --max-time 5 \
    -H "Authorization: Bearer ${access_token}" \
    -H "anthropic-beta: oauth-2025-04-20" \
    -H "Content-Type: application/json" \
    "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

  if [ -z "$response" ]; then
    return 1
  fi

  echo "$response"
}

load_usage_data() {
  local now
  now=$(date +%s)

  # キャッシュが有効かチェック
  if [ -f "$CACHE_FILE" ]; then
    local cache_time
    cache_time=$(jq -r '.cached_at // 0' "$CACHE_FILE" 2>/dev/null)
    local age=$(( now - cache_time ))
    if [ "$age" -lt "$CACHE_TTL" ]; then
      # キャッシュからデータを返す
      cat "$CACHE_FILE"
      return 0
    fi
  fi

  # 新規取得
  local data
  data=$(fetch_usage)
  if [ -n "$data" ]; then
    # キャッシュに保存 (cached_at フィールドを追加)
    echo "$data" | jq --argjson t "$now" '. + {cached_at: $t}' > "$CACHE_FILE" 2>/dev/null
    echo "$data"
    return 0
  fi

  # 取得失敗時はキャッシュを使用 (期限切れでも)
  if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
    return 0
  fi

  return 1
}

# 使用データをロード
usage_data=$(load_usage_data 2>/dev/null)

if [ -n "$usage_data" ]; then
  # utilization は 0-100 のパーセント値
  five_hour_util=$(echo "$usage_data" | jq -r '.five_hour.utilization // 0' 2>/dev/null)
  seven_day_util=$(echo "$usage_data" | jq -r '.seven_day.utilization // 0' 2>/dev/null)

  five_hour_pct=$(echo "$five_hour_util" | awk '{printf "%d", $1}')
  seven_day_pct=$(echo "$seven_day_util" | awk '{printf "%d", $1}')

  # リセット時刻を Asia/Tokyo に変換
  five_hour_reset_raw=$(echo "$usage_data" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
  seven_day_reset_raw=$(echo "$usage_data" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

  if [ -n "$five_hour_reset_raw" ]; then
    ts=$(echo "$five_hour_reset_raw" | sed 's/\.[0-9]*+00:00$/Z/')
    five_hour_reset=$(TZ="Asia/Tokyo" date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" "+%-I%p" 2>/dev/null | tr '[:upper:]' '[:lower:]')
  fi
  if [ -n "$seven_day_reset_raw" ]; then
    ts=$(echo "$seven_day_reset_raw" | sed 's/\.[0-9]*+00:00$/Z/')
    seven_day_reset=$(TZ="Asia/Tokyo" date -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" "+%b %-d %-I%p" 2>/dev/null | tr '[:upper:]' '[:lower:]')
  fi
fi

# --- Line 2: 5時間レート制限 ---
five_bar=$(progress_bar "$five_hour_pct")
five_color=$(usage_color "$five_hour_pct")

line2="${COLOR_GRAY}⏱ 5h${COLOR_RESET}  ${five_color}${five_bar}${COLOR_RESET}  ${five_color}${five_hour_pct}%${COLOR_RESET}"
if [ -n "$five_hour_reset" ]; then
  line2="${line2}  ${COLOR_GRAY}Resets ${five_hour_reset} (Asia/Tokyo)${COLOR_RESET}"
fi

# --- Line 3: 7日間レート制限 ---
seven_bar=$(progress_bar "$seven_day_pct")
seven_color=$(usage_color "$seven_day_pct")

line3="${COLOR_GRAY}📅 7d${COLOR_RESET}  ${seven_color}${seven_bar}${COLOR_RESET}  ${seven_color}${seven_day_pct}%${COLOR_RESET}"
if [ -n "$seven_day_reset" ]; then
  line3="${line3}  ${COLOR_GRAY}Resets ${seven_day_reset} (Asia/Tokyo)${COLOR_RESET}"
fi

# --- 3行を出力 ---
printf '%s\n%s\n%s' "$line1" "$line2" "$line3"
