#!/bin/bash
# validate-bash.sh のテストスイート
# 使用法: /bin/bash package/claude/tests/test-validate-bash.sh
# bash 3.2 (macOS /bin/bash) で実行すること

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATE="$SCRIPT_DIR/../hooks/validate-bash.sh"

passed=0
failed=0

# ヘルパー: コマンドを JSON でラップして validate-bash.sh に渡す
run_hook() {
  local cmd="$1"
  # jq で JSON を生成（コマンド内の特殊文字を正しくエスケープ）
  local json
  json=$(jq -n --arg cmd "$cmd" '{"tool_input":{"command":$cmd}}')
  echo "$json" | /bin/bash "$VALIDATE"
}

# テストケース: deny を期待
expect_deny() {
  local label="$1"
  local cmd="$2"
  local expect_substr="$3"
  local output
  output=$(run_hook "$cmd")
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "FAIL [$label]: exit code $exit_code (expected 0)"
    failed=$((failed + 1))
    return
  fi

  # permissionDecision が deny か確認
  local decision
  decision=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
  if [[ "$decision" != "deny" ]]; then
    echo "FAIL [$label]: expected deny, got '$decision'"
    failed=$((failed + 1))
    return
  fi

  # reason に期待する部分文字列が含まれるか
  if [[ -n "$expect_substr" ]]; then
    local reason
    reason=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason // empty' 2>/dev/null)
    if [[ "$reason" != *"$expect_substr"* ]]; then
      echo "FAIL [$label]: reason missing '$expect_substr'"
      echo "  got: $reason"
      failed=$((failed + 1))
      return
    fi
  fi

  echo "PASS [$label]"
  passed=$((passed + 1))
}

# テストケース: allow を期待（出力なし + exit 0）
expect_allow() {
  local label="$1"
  local cmd="$2"
  local output
  output=$(run_hook "$cmd")
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "FAIL [$label]: exit code $exit_code (expected 0)"
    failed=$((failed + 1))
    return
  fi

  if [[ -n "$output" ]]; then
    echo "FAIL [$label]: expected no output, got:"
    echo "  $output"
    failed=$((failed + 1))
    return
  fi

  echo "PASS [$label]"
  passed=$((passed + 1))
}

echo "=== validate-bash.sh test suite ==="
echo "bash version: $BASH_VERSION"
echo ""

# ── deny テスト ──────────────────────────────

echo "--- Pattern 2: Consecutive quotes ---"
expect_deny "P2: jq double-quote arg" \
  "gh api user --jq '\"\"'" \
  "consecutive quote"

echo "--- Pattern 1: Double-quoted strings ---"
expect_deny "P1: echo with double quotes" \
  'echo "hello"' \
  "double-quoted"
expect_deny "P1: git log with echo" \
  'git log --oneline cfa3a54 -1 && echo "---" && git show cfa3a54 --stat' \
  "double-quoted"

echo "--- Pattern 3: Backslash-escaped whitespace ---"
expect_deny "P3: echo backslash space" \
  'echo hello\ world' \
  "backslash-escaped whitespace"
expect_deny "P3: git format backslash space" \
  'git log --format=%H\ %ai' \
  "backslash-escaped whitespace"

echo "--- Pattern 4: cd + git ---"
expect_deny "P4: cd && git" \
  'cd /tmp && git status' \
  "cd and git"
expect_deny "P4: cd ; git" \
  'cd /tmp; git status' \
  "cd and git"
expect_deny "P4: pushd && git" \
  'pushd /path && git status' \
  "cd and git"

echo "--- Pattern 5: Command substitution ---"
expect_deny "P5: echo with subst" \
  'echo $(whoami)' \
  "command substitution"

echo "--- Pattern 6: Backslash before operator ---"
expect_deny "P6: find -exec \\;" \
  'find . -name foo -exec grep bar {} \;' \
  "backslash before a shell operator"
expect_deny "P6: backslash pipe" \
  'echo test \| cat' \
  "backslash before a shell operator"

# ── allow テスト ──────────────────────────────

echo ""
echo "--- Allow: safe commands ---"
expect_allow "safe: git status" \
  'git status'
expect_allow "safe: git -C" \
  'git -C /tmp status'
expect_allow "safe: ls" \
  'ls -la /tmp'
expect_allow "safe: brew install" \
  'brew install jq'
expect_allow "safe: git format hex" \
  'git log --format=%H%x20%ai'
expect_allow "safe: single-quoted jq" \
  "jq '.field' file.json"
expect_allow "safe: grep single-quoted" \
  "grep 'pattern' file.txt"

echo ""
echo "--- Allow: whitelist ---"
expect_allow "whitelist: git commit heredoc" \
  'git commit -m "$(cat <<'"'"'EOF'"'"'
Commit message here.

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"'

# ── Edge cases ────────────────────────────────

echo ""
echo "--- Edge cases ---"
expect_allow "edge: empty input" \
  ''
expect_allow "edge: git -C with cd in path" \
  'git -C /path/to/cd/repo status'
expect_deny "P2: ordering - consec before dquote" \
  "gh api user --jq '\"\"'" \
  "consecutive quote"

# ── Summary ───────────────────────────────────

echo ""
echo "=== Results: $passed passed, $failed failed ==="
if [[ $failed -gt 0 ]]; then
  exit 1
fi
exit 0
