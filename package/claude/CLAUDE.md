## Plan Review Workflow

### Mandatory Post-Plan Review

After completing a plan (exiting Plan Mode), you MUST:

1. **Launch a subagent** using the Task tool (subagent_type: "general-purpose") to run the `/review` skill (`local-review`).
2. The subagent should review the planned changes and report findings back.
3. **Present the review summary** to the user, highlighting any concerns or suggestions.
4. **Ask the user to confirm** before proceeding with implementation — e.g., "The plan has been reviewed. Would you like me to proceed with implementation?"

This ensures every plan is validated through code review before any code is written, preventing wasted effort on flawed approaches.
