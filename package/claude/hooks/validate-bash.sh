#!/bin/bash
# PreToolUse hook: Bash コマンドのバリデーション
# パーミッション確認を引き起こすパターンを検出し deny + ガイダンスを返す
# bash 3.2 (macOS /bin/bash) 互換 — POSIX ERE のみ使用
# 注意: set -e は意図的に使用しない（jq 失敗時等に fail open するため）

# jq がなければ fail open
command -v jq >/dev/null 2>&1 || exit 0

# stdin を 1 回だけ読み取る
input=$(cat)

cmd=$(jq -r '.tool_input.command // empty' <<< "$input" 2>/dev/null)

if [[ -z "$cmd" ]]; then
  exit 0
fi

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# ── Whitelist ──────────────────────────────────
# git commit + heredoc パターン（CLAUDE.md 推奨の commit 形式）
re_commit="^git commit "
if [[ "$cmd" =~ $re_commit ]] && [[ "$cmd" == *'$(cat <<'* ]]; then
  exit 0
fi

# ── Pattern 2: 連続クォート文字（Pattern 1 より先 — より具体的） ──
# 例: gh api user --jq '""'
re_consec="(^|[[:space:]])[\"'][\"']"
if [[ "$cmd" =~ $re_consec ]]; then
  deny 'Command contains consecutive quote characters at word start (potential obfuscation). Extract jq filter to a variable or avoid nested quotes.'
fi

# ── Pattern 1: ダブルクォート文字列 ──
# 例: echo "hello" / git log && echo "---"
re_dquote="\"[^\"]*\""
if [[ "$cmd" =~ $re_dquote ]]; then
  deny 'Command contains double-quoted strings which trigger permission prompts. Split into multiple Bash calls or use Read/Grep/Glob tools instead.'
fi

# ── Pattern 3: バックスラッシュ空白エスケープ ──
# 例: echo hello\ world / git log --format=%H\ %ai
# glob マッチングを使用（正規表現のエスケープ問題を回避）
if [[ "$cmd" == *'\ '* ]]; then
  deny 'Command contains backslash-escaped whitespace. Use quotes instead, or for git format strings use %xNN hex notation (e.g., %x20 for space).'
fi

# ── Pattern 4: cd と git の併用 ──
# 例: cd /path && git status / cd /path; git status
re_cd="(^|[;&|[:space:]])(cd|pushd)[[:space:]]"
re_git="[;&|][[:space:]]*git([[:space:]]|$)"
if [[ "$cmd" =~ $re_cd ]] && [[ "$cmd" =~ $re_git ]]; then
  deny 'Command combines cd and git in one invocation. Use git -C /path/to/repo <cmd> instead, or split into separate Bash calls.'
fi

# ── Pattern 5: $() コマンド置換 ──
# 例: echo $(whoami)
# glob マッチングを使用
if [[ "$cmd" == *'$('* ]]; then
  deny 'Command contains $() command substitution. Use Glob/Read/Grep tools, or restructure the command to avoid $().'
fi

# ── Pattern 6: シェル演算子前のバックスラッシュ ──
# 例: find . -exec cat {} \;
re_bsop='\\[;|&<>]'
if [[ "$cmd" =~ $re_bsop ]]; then
  deny 'Command contains a backslash before a shell operator (;, |, &, <, >). Use Glob/Grep tools instead, or avoid find -exec (use find -print with pipe).'
fi

exit 0
