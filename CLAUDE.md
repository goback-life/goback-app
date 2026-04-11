# CLAUDE.md — goback

## Stack
Flutter 3.35.5 (FVM) · Supabase 2.10.1 · Riverpod 2.6.1 · Freezed 3.0.6
Package name: `cloudless` · Flavors: `stage` (staging) · `production` (App Store)
All commands: `fvm flutter ...` / `fvm dart ...` — never bare `flutter`/`dart`

## Task Routing (apply automatically — no explicit command needed)
| User says... | Apply workflow |
|---|---|
| New feature / UI change / new screen | `/new-feature` |
| Bug / crash / wrong behaviour | `/fix-bug` |
| Schema change / new table / RLS / column | `/new-migration` |
| Missing tests / untested path | `/add-tests` |
| Ready for TestFlight | `/deploy-beta` |
| Edge function change | `/deploy-functions` |
| Staging validated → App Store | `/promote` |

When intent is ambiguous, state which workflow you're applying and why before starting.

## Architecture Rules
- UI → provider → use case → service → Supabase. No skipping layers.
- No `Supabase.instance` in services — always constructor-inject `SupabaseClient`.
- No Flutter imports in data or service layers.
- `ref.watch` in `build()` only. `ref.read` in methods only.
- `logger.info/warning/error(...)` — never `print`.
- Max 500 lines/file · Max 200 lines/function.

## State Management
- All async state mutations: set `AsyncValue.loading()` first, catch with `(error, stackTrace)`.
- Result pattern: `result.fold((data) => ..., (error) => ...)` — never swallow errors silently.
- Error branches must rethrow or set error state — silent `logger.warning` alone is a bug.

## Models & Code Generation
- All DB models: Freezed + json_serializable. JSON keys = Supabase column names (snake_case).
- Never edit `*.g.dart`, `*.freezed.dart`, `*.tailor.dart` — regenerated and overwritten.
- After any model/annotation change: `fvm dart run build_runner build --delete-conflicting-outputs`

## Supabase Rules
- Schema change → migration file first → staging → validate → production. Never dashboard-only.
- Migration before any code that depends on it.
- `DateTime` stored as `.toUtc().toIso8601String()`.
- RLS required on every new table.

## Environment Strategy
```
local dev  → supabase start              → stage flavor (emulator)
staging    → goback-stage Supabase       → stage flavor → TestFlight internal
production → tvrbqsvxfpyfxvbypvtb        → production flavor → App Store
```
Branch flow: `feature/*` → PR to `develop` → PR to `main` (manual /promote only)

## Session Protocol
1. **Start**: check `docs/claude/handoff.md` → invoke `gsd:resume-work` if found
2. **During**: `/clear` between unrelated tasks — restart over fix-forward when Claude goes off track
3. **Limit**: invoke `gsd:pause-work` → writes handoff.md → then close session

## Bayesian Protocol
State prior → gather evidence → state posterior → gate at ≥95% → log in `docs/claude/confidence-log.md`
- P ≥ 95%: proceed
- P 70–94%: identify specific gap, fix or gather evidence, re-estimate
- P < 70%: stop and ask. Wrong assumption likely.
Uncertainty sources: Riverpod lifecycle edge cases · Supabase auth on cold start · RLS gaps · Freezed codegen drift

## Ralph Wiggum
Use when success criteria are objective and verifiable (tests pass + analyze clean).
Do NOT use for: architectural decisions, security-critical code, anything needing human judgment.
Default: `ralph run -p "task description"` — stop condition: `fvm flutter test && fvm flutter analyze`
Stuck after N iterations → write BLOCKED report to `docs/claude/handoff.md`

## Mandatory Superpowers (not optional)
- `superpowers:test-driven-development` → every new feature / bug fix
- `superpowers:systematic-debugging` → every unexpected test failure
- `superpowers:requesting-code-review` → before every commit to main
- `superpowers:finishing-a-development-branch` → before every merge
- `gsd:pause-work` / `gsd:resume-work` → context management

## Slash Commands
`/new-feature` `/fix-bug` `/new-migration` `/add-tests` `/deploy-beta` `/deploy-functions` `/promote`
Full workflows in `.claude/commands/`

## CLAUDE.md Maintenance
If Claude violates a rule twice → rewrite the rule or move it to `docs/claude/lessons.md`.
If a rule is already followed without being stated → delete it (Claude doesn't need the reminder).
