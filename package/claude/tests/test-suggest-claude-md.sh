#!/bin/bash
# suggest-claude-md.sh のテストスイート
# 使用法: /bin/bash package/claude/tests/test-suggest-claude-md.sh
# bash 3.2 (macOS /bin/bash) で実行すること

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../hooks/suggest-claude-md.sh"

passed=0
failed=0

# ヘルパー: JSON を hook に渡して実行
run_hook() {
  local json="$1"
  local env_vars="${2:-}"
  if [[ -n "$env_vars" ]]; then
    env $env_vars /bin/bash "$HOOK" <<< "$json"
  else
    /bin/bash "$HOOK" <<< "$json"
  fi
}

# テストケース: 出力なし + exit 0 を期待（スキップされる）
expect_skip() {
  local label="$1"
  local json="$2"
  local env_vars="${3:-}"
  local output
  output=$(run_hook "$json" "$env_vars")
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

# テストケース: exit 0 を期待（ランチャー起動は検証しない）
expect_exit_zero() {
  local label="$1"
  local json="$2"
  local output
  output=$(run_hook "$json")
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "FAIL [$label]: exit code $exit_code (expected 0)"
    failed=$((failed + 1))
    return
  fi

  echo "PASS [$label]"
  passed=$((passed + 1))
}

echo "=== suggest-claude-md.sh test suite ==="
echo "bash version: $BASH_VERSION"
echo ""

# ── テスト準備 ──────────────────────────────────

# テスト用の一時 transcript ファイルを作成
tmp_transcript=$(mktemp /tmp/test-transcript-XXXXXX.jsonl)
# 10行以上の JSONL を書き込み
for i in $(seq 1 12); do
  echo '{"type":"human","message":"test message '$i'"}' >> "$tmp_transcript"
done

# 短い transcript（閾値未満）
tmp_short=$(mktemp /tmp/test-transcript-short-XXXXXX.jsonl)
for i in $(seq 1 5); do
  echo '{"type":"human","message":"short message '$i'"}' >> "$tmp_short"
done

# クリーンアップ
cleanup() {
  rm -f "$tmp_transcript" "$tmp_short"
}
trap cleanup EXIT

# ── テストケース ──────────────────────────────────

echo "--- Guard: environment variable ---"
expect_skip "SUGGEST_CLAUDE_MD_RUNNING=1 で即終了" \
  '{}' \
  "SUGGEST_CLAUDE_MD_RUNNING=1"

echo ""
echo "--- Guard: missing fields ---"
expect_skip "空 JSON 入力で即終了" \
  '{}'

expect_skip "session_id 欠如で即終了" \
  '{"transcript_path":"/tmp/nonexistent.jsonl"}'

expect_skip "transcript_path 欠如で即終了" \
  '{"session_id":"test-session-123"}'

echo ""
echo "--- Guard: invalid transcript ---"
expect_skip "存在しないファイルパスで即終了" \
  '{"session_id":"test-session-123","transcript_path":"/tmp/nonexistent-file-12345.jsonl"}'

echo ""
echo "--- Guard: short conversation ---"
expect_skip "短い会話（閾値未満）でスキップ" \
  "{\"session_id\":\"test-session-123\",\"transcript_path\":\"$tmp_short\"}"

echo ""
echo "--- Normal: valid input ---"
expect_exit_zero "正常入力で exit 0" \
  "{\"session_id\":\"test-session-123\",\"transcript_path\":\"$tmp_transcript\"}"

# ── Summary ───────────────────────────────────

echo ""
echo "=== Results: $passed passed, $failed failed ==="
if [[ $failed -gt 0 ]]; then
  exit 1
fi
exit 0
