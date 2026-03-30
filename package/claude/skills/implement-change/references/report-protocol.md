# Report Protocol

All progress reports are sent via `workmux send <coordinator-handle> "<message>"`.

## Message Format

```
PR-N: <status>
```

N is the PR number (1-indexed). status is one of:

| status              | Meaning                                  | Timing                   |
| ------------------- | ---------------------------------------- | ------------------------ |
| セルフレビューPASS  | /pr-review passed with zero issues       | Before push              |
| PR #\<number\> 作成 | Draft PR created + @claude review posted | After push + PR creation |
| CI LGTM             | CI review returned LGTM/Approve          | After CI review passes   |
| 完了                | /minimize-claude-comments executed       | All steps complete       |
| BLOCKED \<reason\>  | Unresolvable issue encountered           | Any time                 |

## BLOCKED Reason Examples

- `BLOCKED テスト失敗: <details>`
- `BLOCKED CIレビュー3回超`
- `BLOCKED ビルドエラー: <details>`

## Coordinator-Side Parsing

Parse received messages by string pattern matching on the status field.

- `完了` → PR is ready for human handoff
- `BLOCKED` → Escalate to human or attempt intervention via `workmux capture` + `workmux send`
- Other statuses → Progress tracking only, no action required
