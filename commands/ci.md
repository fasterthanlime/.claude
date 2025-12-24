Check CI status and fix failing checks

Use `gh checks` to see what's failing on the current PR, then investigate and fix the issues.

Steps:
1. Run `gh checks` to see the status of all checks
2. For any failed checks, fetch the detailed logs
3. Analyze the failure and understand what went wrong
4. Make necessary code fixes
5. Re-run the failing checks locally to verify the fix
6. Commit the fix with an appropriate message
7. Push the changes

This command is useful after creating a PR or when you want to see the CI status without leaving Claude Code.
