#!/bin/bash
# SessionEnd / PreCompact hook: CLAUDE.md 自動改善提案
# 会話履歴を分析し、CLAUDE.md に追記すべきルールを提案する
# bash 3.2 (macOS /bin/bash) 互換 — fail open 設計
# 注意: set -e は意図的に使用しない（エラー時 fail open するため）

# 無限ループ防止: ランチャーから起動された claude が再帰的に hook を発火しないようにする
if [[ -n "${SUGGEST_CLAUDE_MD_RUNNING:-}" ]]; then
  exit 0
fi

# jq がなければ fail open
command -v jq >/dev/null 2>&1 || exit 0

# stdin を 1 回だけ読み取る
input=$(cat)

# session_id と transcript_path を抽出
session_id=$(jq -r '.session_id // empty' <<< "$input" 2>/dev/null)
transcript_path=$(jq -r '.transcript_path // empty' <<< "$input" 2>/dev/null)

# バリデーション: 必須フィールドが欠如している場合はスキップ
if [[ -z "$session_id" ]]; then
  exit 0
fi

if [[ -z "$transcript_path" ]]; then
  exit 0
fi

# transcript ファイルの存在チェック
if [[ ! -f "$transcript_path" ]]; then
  exit 0
fi

# 会話の長さチェック: 短すぎる会話はスキップ（閾値: JSONL 10行未満）
line_count=$(wc -l < "$transcript_path" 2>/dev/null)
line_count=${line_count:-0}
# wc -l の出力から余分な空白を除去
line_count=$(echo "$line_count" | tr -d ' ')
if [[ "$line_count" -lt 10 ]]; then
  exit 0
fi

# ランチャースクリプトのパス
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAUNCHER="$SCRIPT_DIR/../scripts/suggest-claude-md-launcher.sh"

if [[ ! -x "$LAUNCHER" ]]; then
  exit 0
fi

# バックグラウンドでランチャーを起動
# 環境変数で必要な情報を渡す
SUGGEST_CLAUDE_MD_RUNNING=1 \
SESSION_ID="$session_id" \
TRANSCRIPT_PATH="$transcript_path" \
CWD="${PWD}" \
  nohup /bin/bash "$LAUNCHER" >/dev/null 2>&1 &

exit 0
