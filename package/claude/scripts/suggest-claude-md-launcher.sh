#!/bin/bash
# CLAUDE.md 改善提案ランチャー
# suggest-claude-md.sh からバックグラウンドで起動される分析本体
# bash 3.2 (macOS /bin/bash) 互換

set -euo pipefail

# 環境変数から引数を受け取る
SESSION_ID="${SESSION_ID:?SESSION_ID is required}"
TRANSCRIPT_PATH="${TRANSCRIPT_PATH:?TRANSCRIPT_PATH is required}"
CWD="${CWD:-$PWD}"

# 無限ループ防止（環境変数が設定されていることを確認）
export SUGGEST_CLAUDE_MD_RUNNING=1

# jq がなければ終了
command -v jq >/dev/null 2>&1 || exit 1

# claude CLI がなければ終了
command -v claude >/dev/null 2>&1 || exit 1

# ── 会話履歴の抽出 ──────────────────────────────
# JSONL からユーザー/アシスタントのテキストメッセージのみ抽出
conversation=$(jq -r '
  select(.type == "human" or .type == "assistant") |
  if .type == "human" then
    "USER: " + (
      if (.message | type) == "array" then
        [.message[] | select(.type == "text") | .text] | join("\n")
      elif (.message | type) == "string" then
        .message
      else
        ""
      end
    )
  elif .type == "assistant" then
    "ASSISTANT: " + (
      if (.message | type) == "array" then
        [.message[] | select(.type == "text") | .text] | join("\n")
      elif (.message.content | type) == "array" then
        [.message.content[] | select(.type == "text") | .text] | join("\n")
      elif (.message | type) == "string" then
        .message
      else
        ""
      end
    )
  else
    empty
  end
' "$TRANSCRIPT_PATH" 2>/dev/null)

if [[ -z "$conversation" ]]; then
  exit 0
fi

# 長すぎる会話は末尾 200 行に切り詰め
conversation=$(echo "$conversation" | tail -200)

# ── CLAUDE.md の読み込み ──────────────────────────
global_claude_md=""
project_claude_md=""

# グローバル CLAUDE.md
if [[ -f "${HOME}/.config/claude/CLAUDE.md" ]]; then
  global_claude_md=$(cat "${HOME}/.config/claude/CLAUDE.md")
fi

# プロジェクト CLAUDE.md（CWD から探索）
if [[ -f "${CWD}/CLAUDE.md" ]]; then
  project_claude_md=$(cat "${CWD}/CLAUDE.md")
fi

# ── 分析プロンプトの構築 ──────────────────────────
tmpfile=$(mktemp /tmp/suggest-claude-md-prompt-XXXXXX)
trap 'rm -f "$tmpfile"' EXIT

cat > "$tmpfile" << 'PROMPT_HEADER'
あなたは CLAUDE.md ファイルの改善提案を行うアナリストです。
以下の会話履歴を分析し、CLAUDE.md に追記すべきルールやガイダンスを提案してください。

## 分析観点

1. **繰り返しパターン**: ユーザーが何度も同じ指摘や修正を行っているパターン
2. **エラーからの学び**: アシスタントが犯したミスから導き出せるルール
3. **プロジェクト固有の慣習**: コードベース特有の規約や制約
4. **ツール使用制約**: 特定のツールやコマンドの使用に関する制約
5. **ワークフロー改善**: 開発ワークフローを効率化するためのルール

## 出力形式

提案がある場合のみ、以下の形式で出力してください。提案がない場合は「提案なし」とだけ出力してください。

各提案について:
- **タイトル**: 簡潔なルール名
- **根拠**: 会話のどの部分からこの提案が導かれたか
- **追加先**: グローバル CLAUDE.md / プロジェクト CLAUDE.md
- **追記内容案**: CLAUDE.md にそのまま追記できる Markdown テキスト
- **優先度**: 高 / 中 / 低

## 制約

- 既存の CLAUDE.md と重複する提案はしない
- 一般的すぎるルール（「コードをきれいに書く」等）は除外
- 具体的で actionable な提案のみ
- 日本語で出力
- 最大 5 件まで

PROMPT_HEADER

# 既存 CLAUDE.md の内容を追加
{
  echo ""
  echo "## 現在のグローバル CLAUDE.md"
  echo ""
  if [[ -n "$global_claude_md" ]]; then
    echo "$global_claude_md"
  else
    echo "(なし)"
  fi
  echo ""
  echo "## 現在のプロジェクト CLAUDE.md"
  echo ""
  if [[ -n "$project_claude_md" ]]; then
    echo "$project_claude_md"
  else
    echo "(なし)"
  fi
  echo ""
  echo "## 会話履歴"
  echo ""
  echo "$conversation"
} >> "$tmpfile"

# ── claude CLI で分析実行 ──────────────────────────
timestamp=$(date +%Y%m%d%H%M%S)
logfile="/tmp/suggest-claude-md-${SESSION_ID}-${timestamp}.log"

claude --dangerously-skip-permissions --output-format text --print -p "$(cat "$tmpfile")" > "$logfile" 2>&1

# ── 結果の通知 ──────────────────────────────────
# macOS: ターミナルに結果を表示
if [[ "$(uname)" == "Darwin" ]] && command -v osascript >/dev/null 2>&1; then
  osascript -e "
    tell application \"Terminal\"
      activate
      do script \"echo '=== CLAUDE.md 改善提案 ===' && cat '$logfile' && echo '' && echo '=== ログ: $logfile ==='\"
    end tell
  " 2>/dev/null || true
fi

# ── 古いログのクリーンアップ ──────────────────────
# 7日以上古い suggest-claude-md ログを削除
find /tmp -name 'suggest-claude-md-*' -mtime +7 -delete 2>/dev/null || true

exit 0
