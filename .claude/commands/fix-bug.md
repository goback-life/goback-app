# /fix-bug

Fix a bug with root-cause-first debugging, a regression test, and autonomous iteration.

## Steps

1. **Systematic debugging**
   Invoke `superpowers:systematic-debugging`.

2. **State Bayesian prior**
   "I believe the root cause is X because..."
   State confidence %. If P < 70%, investigate more before writing any code.

3. **Gather evidence**
   Reproduce the bug. Read logs. Trace the call stack.
   Update posterior. P(I know the root cause) must reach ≥80% before fixing.

4. **Branch**
   ```bash
   git checkout -b fix/$ARGUMENTS develop
   ```

5. **Write failing test first**
   The test must reproduce the bug exactly.
   Commit the failing test before writing the fix.

6. **Ralph loop**
   ```
   ralph run -p "Fix $ARGUMENTS.
   The reproducing test must pass. Full test suite must stay green.
   flutter analyze must return zero issues.
   Output TASK_COMPLETE when done or BLOCKED after 15 iterations without progress."
   ```

7. **Bayesian gate**
   P(root cause fixed, regression covered, nothing broken) ≥95%.

8. **Lessons**
   If the bug reveals a pattern, append to `docs/claude/lessons.md`.

9. **Commit + PR**
   ```bash
   git commit -m "fix: $ARGUMENTS"
   gh pr create --base develop --title "fix: $ARGUMENTS"
   ```
