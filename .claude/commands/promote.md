# /promote

Promote develop → main. Triggers production migration + App Store build.
This is the gate before anything reaches real users.

## Steps

1. **Verify staging is clean**
   - All features in develop have been tested on TestFlight internal
   - No known blockers in `docs/claude/known-issues.md`
   - All pending migrations have been applied to staging and validated

2. **Full pre-checks**
   ```bash
   fvm flutter test
   fvm flutter analyze
   cat logs/analyze_last.log
   ```
   Zero failures, zero issues.

3. **Branch finishing checklist**
   Invoke `superpowers:finishing-a-development-branch`.

4. **Code review**
   Invoke `superpowers:requesting-code-review` on the develop → main diff.

5. **Bayesian gate**
   P(this release is safe for all production users) ≥95%.
   State the specific risks and why they're acceptable or mitigated.
   Log to `docs/claude/confidence-log.md`.

6. **Open PR**
   ```bash
   gh pr create --base main --head develop \
     --title "release: $(date +%Y-%m-%d)" \
     --body "## Changes\n$(git log main..develop --oneline)"
   ```

7. **Manual approval**
   Do not merge without explicit approval. This step requires human sign-off.

8. **On merge — CI automatically runs**
   - `supabase db push` → production Supabase
   - `flutter build` production flavor
   - Fastlane lanes available via `workflow_dispatch`:
     ```bash
     fastlane ios release
     fastlane android release
     ```

## Rules
- Never push directly to main.
- Production migration only happens on merge to main via CI — never manually.
- If a regression is found post-merge: fix in a hotfix branch off main, not develop.
