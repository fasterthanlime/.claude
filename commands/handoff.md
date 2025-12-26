Write a handoff document to `.handoffs/` so a future Claude session can continue your work.

**CRITICAL: You are likely running low on context. Do NOT read files, run commands, or explore. Use ONLY what is already in your memory.**

Write the handoff in a single Bash command using a heredoc:

```bash
mkdir -p .handoffs && cat > ".handoffs/$(date +%Y-%m-%d-%H%M%S)-DESCRIPTION.md" << 'EOF'
# Handoff: TITLE

## Current State
What's done, what's in progress

## Next Steps
Prioritized list of what remains

## Key Files
- `path/to/file.rs` - brief description of why it matters

## Gotchas
Non-obvious context, failed approaches, important decisions

## Bootstrap
\`\`\`bash
# Single command to verify state or continue work
\`\`\`
EOF
```

Replace DESCRIPTION and TITLE appropriately. Write from memory only.

After writing, reply: "🫡 Run `/clear` then `/rise` to continue"
