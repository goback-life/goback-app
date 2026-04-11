# /new-migration

Create and apply a Supabase database migration safely: staging first, production via /promote.

## Steps

1. **Sync current schema**
   ```bash
   supabase db pull --linked
   ```
   This creates a migration file capturing the current remote state.
   If no migrations exist yet, this is the baseline snapshot.

2. **State Bayesian prior**
   "P(I understand the current schema and this change is safe) = X% because..."
   Must be ≥90% before writing SQL. If not, inspect the pulled schema first.

3. **Manual validation (critical on first run)**
   Compare pulled schema against Supabase dashboard.
   Verify: tables, columns, RLS policies, functions, triggers, storage buckets.
   Note any discrepancies in `docs/claude/known-issues.md`.

4. **Create migration**
   ```bash
   supabase migration new $ARGUMENTS
   ```
   Write SQL in the generated file at `supabase/migrations/<timestamp>_$ARGUMENTS.sql`.
   Include: table/column changes, RLS policies, indexes.

5. **Apply to staging**
   ```bash
   supabase db push --linked --project-ref $SUPABASE_STAGE_PROJECT_REF
   ```
   Run the app against staging. Validate the change works end-to-end.

6. **Regenerate Dart types**
   ```bash
   supabase gen types dart --linked > lib/core/features/supabase/generated_types.dart
   ```

7. **Update architecture doc**
   If the schema change affects documented data flow, update `docs/claude/architecture.md`.

8. **Bayesian gate**
   P(migration is correct, staging validated, production safe) ≥95%.
   Log to `docs/claude/confidence-log.md`.

9. **Commit migration before any dependent code**
   ```bash
   git add supabase/migrations/
   git commit -m "chore: migration — $ARGUMENTS"
   ```
   Production migration happens automatically via /promote when merged to main.

## Rules
- Never push a migration directly to production — always staging first.
- Never write code that depends on a schema change before the migration is committed.
- If a migration must be rolled back: create a new migration that reverses it.
