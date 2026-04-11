# /deploy-beta

Build and upload to TestFlight internal track for device testing.

## Deployment flow
Emulator (local) → TestFlight internal → TestFlight external → App Store

## Steps

1. **Full test suite**
   ```bash
   fvm flutter test
   ```
   Must be all green. Fix failures before proceeding.

2. **Static analysis**
   ```bash
   fvm flutter analyze
   ```
   Zero issues required. Check `logs/analyze_last.log` if hook ran it in background.

3. **Branch finishing checklist**
   Invoke `superpowers:finishing-a-development-branch`.

4. **Bayesian gate**
   P(this build is safe to ship to internal testers) ≥95%.
   Consider: known crashes, data migration state, API compatibility.

5. **iOS build + TestFlight upload**
   ```bash
   fastlane ios beta
   ```
   This builds the `stage` flavor, increments build number from git commit count,
   and uploads to TestFlight internal track.

6. **Android build (optional)**
   ```bash
   fastlane android beta
   ```
   Uploads to Play Store internal track.

7. **Log known issues**
   If shipping with known bugs or incomplete features, log them:
   `docs/claude/known-issues.md` → Shipped Known Issues section.

## Notes
- TestFlight internal = immediate availability to internal testers (no Apple review)
- TestFlight external = requires Apple review (1–3 days)
- Promote to external manually in App Store Connect when internal testing passes
