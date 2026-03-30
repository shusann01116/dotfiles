---
name: implement-change
description: |
  This skill should be used when the user asks to "implement a change",
  "implement site-layout-ui", "この change を実装して", "openspec の実装を進めて",
  "change を実行", or references an OpenSpec change directory for implementation.
  Orchestrates parallel worktree agents via workmux to autonomously implement
  OpenSpec changes with self-review, CI review, and minimize loops.
  All PRs reach CI LGTM state before human handoff.
---

# Implement Change

Autonomous coordinator skill for implementing OpenSpec changes via parallel worktree agents.

## Overview

Read an OpenSpec change directory, determine PR split strategy, spawn worktree agents via workmux, and monitor until all PRs reach CI LGTM state.

- **Input**: `/implement-change <change-name>`
- **Prerequisites**: Spec PR merged. `openspec/changes/<change-name>/` exists with proposal.md, design.md, tasks.md, specs/\*/spec.md.
- **Output**: All PRs in draft state with CI LGTM and comments minimized. Ready for human review.

## Coordinator Launch

Launch the coordinator itself inside a workmux worktree to obtain a handle for receiving agent reports.

```bash
workmux add implement-<change-name> -p "/implement-change <change-name>"
```

The coordinator handle (e.g., `implement-site-layout-ui`) is passed to all agents for `workmux send` reporting.

## Core Workflow

1. **Read context** — Read `openspec/changes/<change-name>/` in full (proposal.md, design.md, tasks.md, specs/\*/spec.md, .openspec.yaml)
2. **Determine PR split** — Analyze task dependencies and design to decide PR granularity, dependency graph → Phases, branch names, and PR titles
3. **Spawn Phase N agents** — Write prompt files from template, then `workmux add -b -P` for each PR
4. **Confirm launch** — `workmux wait <handles> --status working --timeout 120`
5. **Wait for completion** — `workmux wait <handles> --timeout 7200`. Receive `workmux send` reports from agents
6. **Phase transition** — When all agents report `完了`, spawn next Phase. Repeat from step 3
7. **Human handoff** — Display summary table of all PRs with numbers, branches, CI status, and URLs

For detailed step-by-step instructions, read `references/coordinator-flow.md`.

## PR Split Criteria

- Target context separation, independent testability, ~300 line diffs as guideline
- Prioritize task boundaries from tasks.md over line count
- Exclude test files and stories from line counts
- Group independent PRs into the same Phase; dependent PRs into later Phases

## Agent Spawning

To generate a prompt file for each agent:

1. Read `references/agent-prompt.md` template
2. Replace placeholders with task-specific values from tasks.md and design.md
3. Inline the session flow from `references/agent-flow.md` into the prompt
4. Spawn: `workmux add <branch> -b -P <prompt-file>`

Prompt generation rules:

- Self-contained (agents cannot see coordinator conversation)
- Use relative paths (each worktree has its own root)
- Preserve `_Leverage`, `_Prompt`, `_Verification` fields from tasks.md verbatim
- Extract only relevant design.md sections, not the full document

Agents handle CI review feedback directly via `gh api` — do NOT delegate to `/pr-review-response`.

## Report Protocol

Agents report via `workmux send <coordinator-handle> "PR-N: <status>"`.

| Status             | Meaning            |
| ------------------ | ------------------ |
| セルフレビューPASS | Self-review passed |
| PR #N 作成         | Draft PR created   |
| CI LGTM            | CI review approved |
| 完了               | All steps complete |
| BLOCKED \<reason\> | Unresolvable issue |

For full protocol details, read `references/report-protocol.md`.

## Error Handling

On BLOCKED reports: run `workmux capture <handle>` for details, then either send instructions via `workmux send` or escalate to human.

For the complete error matrix, read `references/error-handling.md`.

## Reference Files

- **`references/coordinator-flow.md`** — Detailed coordinator Steps 1-6 with Phase transition rules
- **`references/agent-flow.md`** — Agent session flow (implement → review → PR → CI → minimize)
- **`references/agent-prompt.md`** — Prompt file template with placeholders
- **`references/report-protocol.md`** — Report message format and status values
- **`references/error-handling.md`** — Error matrix and escalation protocol

## Related Skills

- `/coordinator` — Generic worktree agent orchestration (base pattern)
- `/workmux` — workmux CLI reference
- `/pr-review` — PR review (general quality + DDD)
- `/minimize-claude-comments` — Fold PR bot comments
- `/test-driven-development` — TDD implementation
