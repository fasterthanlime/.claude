Continue work from the latest handoff document.

**Step 1: Immediately cat the latest handoff (single command, no exploration):**

```bash
/bin/ls -t .handoffs/*.md 2>/dev/null | head -1 | xargs cat 2>/dev/null || echo "No handoffs found"
```

**Step 2: If a handoff was found, ask the user:**

Present the handoff content, then use AskUserQuestion with options like:
- "Continue with next steps from handoff"
- "Focus on a specific item" (if multiple next steps exist)
- "Something else"

Do NOT automatically read key files or run commands. Wait for user direction.

**If no handoffs exist:** Ask what the user wants to work on.
