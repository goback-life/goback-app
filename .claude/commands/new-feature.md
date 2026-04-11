# /new-feature

Implement a new feature with TDD, autonomous iteration, and code review.

## Steps

1. **Branch + worktree**
   ```bash
   git worktree add ../goback-worktrees/feat-$ARGUMENTS -b feature/$ARGUMENTS
   ```
   Work in the worktree directory for full isolation.

2. **Scope the task**
   Read only the files directly relevant to this feature.
   Read `docs/claude/patterns.md` and `docs/claude/architecture.md`.
   Do NOT scan the whole repo.

3. **State Bayesian prior**
   "P(I understand the requirements and affected code) = X% because..."
   Must be ≥90% to proceed. If not, read more files, then re-estimate.

4. **TDD**
   Invoke `superpowers:test-driven-development`.
   Write failing tests that define the feature before writing any implementation.

5. **Ralph loop**
   ```
   ralph run -p "Implement $ARGUMENTS.
   All tests must pass. flutter analyze must return zero issues.
   Output TASK_COMPLETE when done or BLOCKED after 20 iterations without progress."
   ```

6. **Code review**
   Invoke `superpowers:requesting-code-review` (fresh subagent context).
   Address all findings before proceeding.

7. **Bayesian gate**
   P(correct, tested, won't break anything) ≥95%.
   Log to `docs/claude/confidence-log.md`.

8. **Commit + PR**
   ```bash
   git commit -m "feat: $ARGUMENTS"
   gh pr create --base develop --title "feat: $ARGUMENTS"
   ```

9. **Cleanup**
   ```bash
   git worktree remove ../goback-worktrees/feat-$ARGUMENTS
   ```
