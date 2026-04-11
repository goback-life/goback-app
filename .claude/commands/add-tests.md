# /add-tests

Add test coverage to an existing file with autonomous iteration until the suite is green.

## Steps

1. **Read the target file completely**
   Understand every method, state transition, error path, and edge case.
   Do not start until the file is fully read.

2. **Audit untested paths**
   List every code path that has no test:
   - Provider state transitions (loading → data → error)
   - Use case success + failure branches
   - Mapper edge cases (null fields, unexpected values)
   - Cache boundary conditions

3. **Check existing patterns**
   Read `docs/claude/testing.md` and `test/test_utils/` before writing any test.
   Match the existing test structure exactly.

4. **Ralph loop**
   ```
   ralph run -p "Write tests for $ARGUMENTS covering all untested paths.
   All tests must pass. No existing tests may break.
   Output TASK_COMPLETE when done or BLOCKED after 15 iterations."
   ```

5. **Bayesian gate**
   P(all meaningful paths tested, tests are correct, nothing regressed) ≥95%.

6. **Commit**
   ```bash
   git commit -m "test: add coverage for $ARGUMENTS"
   ```

## What to test
- Every public method with non-trivial logic
- Error states and recovery
- Boundary values (empty lists, null optionals, max sizes)
- Async state transitions

## What not to test
- Generated code (*.g.dart, *.freezed.dart)
- One-liner passthrough providers
- Pure widget rendering (unless conditional logic present)
