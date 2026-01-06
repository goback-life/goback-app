# Developer Workflow Guide

This guide covers the complete development-to-production workflow for the goback app.

## Table of Contents
1. [Daily Development Workflow](#daily-development-workflow)
2. [Git Workflow](#git-workflow)
3. [Testing in Production](#testing-in-production)
4. [Publishing to App Stores](#publishing-to-app-stores)
5. [Quick Reference](#quick-reference)

---

## Daily Development Workflow

### Morning Setup (First Time Each Day)

1. **Pull latest changes from main branch:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create/switch to your feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   # OR if branch already exists:
   git checkout feature/your-feature-name
   git pull origin feature/your-feature-name
   ```

3. **Start build_runner watch (in a separate terminal):**
   ```bash
   fvm dart run build_runner watch --delete-conflicting-outputs
   ```
   Keep this running in the background.

4. **Run the app in stage environment:**
   ```bash
   fvm flutter run --flavor stage
   ```
   This connects to your staging Supabase project.

### During Development

1. **Make your code changes** in your IDE
2. **Save files** - Flutter automatically hot reloads
3. **Test your changes** in the running app
4. **Commit frequently** (see Git Workflow section)

### After Making Changes

**If you added/removed packages:**
```bash
fvm flutter pub get
# Then rebuild the app
```

**If you changed code with annotations (@riverpod, @freezed, etc.):**
- `build_runner watch` will automatically regenerate code
- Flutter will hot reload automatically

**If hot reload stops working:**
- Press `r` in the terminal to manually hot reload
- Press `R` for hot restart (full restart without rebuild)
- If still not working, stop and restart the app

### Lunch Break / End of Day

1. **Stop the app:** Press `Ctrl+C` in the terminal
2. **Close the emulator** (optional)
3. **Keep `build_runner watch` running** (or stop it if you prefer)

### After Lunch / Next Session

1. **Just run the app again** (no rebuild needed):
   ```bash
   fvm flutter run --flavor stage
   ```
   This uses cached builds and is much faster.

---

## Git Workflow

### Branch Strategy

We use a **feature branch workflow**:

```
main (production-ready code)
  ├── develop (optional: integration branch)
  ├── feature/new-feature
  ├── feature/bug-fix
  └── hotfix/critical-fix
```

### Daily Git Workflow

#### 1. Starting Work on a Feature

```bash
# Make sure you're on main and up to date
git checkout main
git pull origin main

# Create a new feature branch
git checkout -b feature/add-user-profile

# Push the branch to remote (so others can see it)
git push -u origin feature/add-user-profile
```

#### 2. During Development (Commit Frequently)

```bash
# Stage your changes
git add .

# Commit with a clear message
git commit -m "feat: add user profile page UI"

# Push to remote regularly (at least daily)
git push origin feature/add-user-profile
```

**Commit Message Format:**
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `style:` - Formatting, missing semicolons, etc.
- `test:` - Adding tests
- `chore:` - Maintenance tasks

**Examples:**
```bash
git commit -m "feat: implement phone number authentication"
git commit -m "fix: resolve crash when loading empty feed"
git commit -m "refactor: extract auth logic to separate service"
```

#### 3. When Feature is Complete

```bash
# Make sure all changes are committed
git status

# Push any final commits
git push origin feature/add-user-profile

# Create a Pull Request (PR) on GitHub/GitLab
# - Title: "feat: Add user profile page"
# - Description: Explain what the PR does
# - Request review from team members
```

#### 4. After PR is Approved and Merged

```bash
# Switch back to main
git checkout main

# Pull the merged changes
git pull origin main

# Delete the local feature branch (optional cleanup)
git branch -d feature/add-user-profile

# Delete remote branch (if it wasn't auto-deleted)
git push origin --delete feature/add-user-profile
```

### When to Pull/Push

**Pull from main:**
- Every morning before starting work
- Before creating a new feature branch
- If you're working on a long-lived branch, pull main weekly to stay updated

**Push to your feature branch:**
- After each logical commit (at least daily)
- Before leaving for the day
- Before creating a PR

**Never push directly to main** - Always use Pull Requests!

### Handling Conflicts

If you get conflicts when pulling:

```bash
# Pull with rebase to keep history clean
git pull --rebase origin main

# If conflicts occur:
# 1. Fix conflicts in your IDE
# 2. Stage the fixed files
git add .
# 3. Continue the rebase
git rebase --continue
```

---

## Testing in Production

Before publishing, you should test the production build locally.

### 1. Switch to Production Environment

DECRYPT FIREBASE 
**Update your `.env` file temporarily:**
```bash
# Change these to production values
SUPABASE_PROJECT_URL=https://your-production-project.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key
```

⚠️ **Important:** Remember to switch back to staging after testing!

### 2. Build Production Release

**Android:**
```bash
fvm flutter build apk --release --flavor production
# OR for App Bundle (for Play Store):
fvm flutter build appbundle --release --flavor production
```

**iOS:**
```bash
fvm flutter build ios --release --flavor production
```

### 3. Test the Production Build

- Install the APK/IPA on a physical device or emulator
- Test all critical flows
- Verify it connects to production Supabase
- Check that all features work as expected

### 4. Switch Back to Staging

**Update `.env` back to staging:**
```bash
SUPABASE_PROJECT_URL=https://your-staging-project.supabase.co
SUPABASE_ANON_KEY=your-staging-anon-key
```

### 5. Run Production Build Locally (Optional)

You can also run production flavor directly:
```bash
fvm flutter run --release --flavor production
```

⚠️ **Warning:** This connects to production! Only do this for final testing.

---

## Publishing to App Stores

### Pre-Release Checklist

- [ ] All tests pass
- [ ] Code reviewed and merged to `main`
- [ ] Production build tested locally
- [ ] Version number updated in `pubspec.yaml`
- [ ] CHANGELOG.md updated (if you maintain one)
- [ ] Production Supabase database is ready
- [ ] All environment variables are correct

### 1. Prepare for Release

**Update version in `pubspec.yaml`:**
```yaml
version: 1.0.2+2  # Format: major.minor.patch+buildNumber
```

**Commit the version bump:**
```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.2"
git push origin main
```

### 2. Build Release Artifacts

**Android (Google Play Store):**
```bash
# Build App Bundle (required for Play Store)
fvm flutter build appbundle --release --flavor production

# Output: build/app/outputs/bundle/productionRelease/app-production-release.aab
```

**iOS (App Store):**
```bash
# Build iOS release
fvm flutter build ios --release --flavor production

# Then open Xcode to archive and upload:
open ios/Runner.xcworkspace
# In Xcode: Product → Archive → Distribute App
```

### 3. Upload to Stores

**Google Play Store:**
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to "Production" → "Create new release"
4. Upload the `.aab` file
5. Fill in release notes
6. Review and roll out

**Apple App Store:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select "Any iOS Device" as target
3. Product → Archive
4. In Organizer window: Distribute App
5. Follow the App Store Connect upload process
6. Go to [App Store Connect](https://appstoreconnect.apple.com)
7. Submit for review

### 4. Post-Release

**Tag the release in Git:**
```bash
git tag -a v1.0.2 -m "Release version 1.0.2"
git push origin v1.0.2
```

**Create a GitHub Release (optional):**
- Go to GitHub → Releases → Create new release
- Select the tag you just created
- Add release notes
- Attach any relevant files

---

## Quick Reference

### Daily Commands

```bash
# Start development
git checkout main && git pull origin main
git checkout -b feature/my-feature
fvm dart run build_runner watch --delete-conflicting-outputs  # Terminal 1
fvm flutter run --flavor stage  # Terminal 2

# Commit and push
git add .
git commit -m "feat: description"
git push origin feature/my-feature

# Switch back to main
git checkout main
git pull origin main
```

### Build Commands

```bash
# Development (stage)
fvm flutter run --flavor stage

# Production test build
fvm flutter run --release --flavor production

# Release builds
fvm flutter build appbundle --release --flavor production  # Android
fvm flutter build ios --release --flavor production       # iOS
```

### Git Commands

```bash
# Create feature branch
git checkout -b feature/name

# Commit changes
git add .
git commit -m "type: description"

# Push to remote
git push origin feature/name

# Update from main
git checkout main
git pull origin main
git checkout feature/name
git merge main  # or git rebase main
```

### Environment Switching

**Stage (Development):**
```bash
# In .env file:
SUPABASE_PROJECT_URL=https://your-staging-project.supabase.co
SUPABASE_ANON_KEY=your-staging-anon-key
```

**Production:**
```bash
# In .env file:
SUPABASE_PROJECT_URL=https://your-production-project.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key
```

⚠️ **Always switch back to staging after production testing!**

---

## Troubleshooting

### Build Issues

**Clean build:**
```bash
fvm flutter clean
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
```

### Git Issues

**Undo last commit (keep changes):**
```bash
git reset --soft HEAD~1
```

**Undo last commit (discard changes):**
```bash
git reset --hard HEAD~1
```

**View commit history:**
```bash
git log --oneline --graph --all
```

### Environment Issues

**Check current environment:**
```bash
# Look at .env file
cat .env | grep SUPABASE
```

**Verify Supabase connection:**
- Check the app logs when it starts
- Look for "Supabase initialized successfully" message

---

## Best Practices

1. **Commit often** - Small, frequent commits are better than large ones
2. **Write clear commit messages** - Future you will thank you
3. **Test in stage first** - Never test directly in production
4. **Pull before starting work** - Stay up to date with main
5. **Use feature branches** - Never commit directly to main
6. **Review before merging** - Always use Pull Requests
7. **Keep build_runner watch running** - For smooth development
8. **Test production builds** - Before publishing to stores
9. **Tag releases** - Makes it easy to track versions
10. **Document breaking changes** - In commit messages and PRs

---

## Workflow Summary

```
Daily Development:
1. Pull main → Create feature branch → Develop in stage → Commit & push
2. Create PR → Review → Merge to main

Before Release:
1. Test in production locally → Fix issues → Merge to main

Release:
1. Bump version → Build release → Upload to stores → Tag release
```

---

**Questions?** Check the main [README.md](README.md) or ask your team!

