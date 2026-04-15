# Lessons

Format: [lesson] → [why it matters] → [what to do instead]

## From Codebase Archaeology

- Build-phase provider mutations cause `ProviderScope` errors: `ref.read` inside `build()` of a
  widget triggers during the widget tree build phase, mutating provider state and crashing.
  → Use `WidgetsBinding.instance.addPostFrameCallback` or defer with `Future.microtask`.
  (Source: fix in 9ef3c21 — lockout friends overlay)

- Dead code silently accumulates: the semantic compression pass (e5089a7) removed 4,320 LOC and
  22+ files that were unreachable. Unreachable code is invisible until a dedicated audit.
  → Delete code the moment a feature is replaced, not "later".

- 0hr/1min lockout options caused UX confusion and were removed (3ab545a). Minimum meaningful
  increment matters — don't expose time granularity that has no real use.
  → Always validate that every selectable option in a UI corresponds to a meaningful action.

- Lockout session join errors (RPC "already in active lockout") surfaced late because the RPC
  error was not propagated — it was swallowed in a fold branch that only logged a warning.
  → Error branches in `result.fold` must either rethrow or set error state; silent logging
  alone causes the UI to appear successful when it isn't.

- Generated files (*.g.dart, *.freezed.dart) must never be edited manually. build_runner
  overwrites them without warning. Any manual change is silently lost.
  → If generated output is wrong, fix the source annotation, not the generated file.

## From Development (ongoing — add here when corrected)

- Background tasks must not be left running between sessions. This machine has limited resources
  and orphaned processes consume them unnecessarily.
  → Always clean up background tasks before ending a session. Never leave a `run_in_background`
  command running unless it is explicitly meant to outlive the conversation.
