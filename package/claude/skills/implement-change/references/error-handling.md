# Error Handling

## Error Matrix

| Situation                       | Agent Action                                                        | Coordinator Action                                                                                                         |
| ------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| Tests fail (self-resolvable)    | Fix → /pr-review loop → continue                                    | No intervention                                                                                                            |
| Tests fail (unresolvable)       | `workmux send "PR-N: BLOCKED テスト失敗: <details>"`                | `workmux capture` for details → `workmux send` with instructions, or escalate to human                                     |
| CI review exceeds 3 rounds      | `workmux send "PR-N: BLOCKED CIレビュー3回超"`                      | Escalate to human                                                                                                          |
| API overload (529) / 500 errors | Auto-retry (Claude Code standard behavior). Continue after recovery | No intervention                                                                                                            |
| workmux send failure            | Exit with `done` status. Report is lost                             | Detect `done` via `workmux wait` → `workmux capture` for fallback status check                                             |
| Phase N PR partially BLOCKED    | —                                                                   | Continue non-BLOCKED PRs. BLOCKED PRs await human resolution. Phase N+1 proceeds only for PRs not depending on BLOCKED PRs |
| Agent fails to launch           | —                                                                   | `workmux wait --status working --timeout 120` detects timeout → escalate to human                                          |

## Escalation Protocol

When the coordinator cannot resolve an issue autonomously:

1. Run `workmux status` to get all agent statuses
2. Run `workmux capture <handle>` on BLOCKED agents for terminal output
3. Display a summary to the human:
   - List of all PRs with their current status
   - BLOCKED PR details (reason + last 50 lines of terminal output)
   - Suggested next steps
4. Wait for human instructions before proceeding
