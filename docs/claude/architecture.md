# Architecture

## Layer Boundaries
```
UI (presentation/) → providers (domain/providers/) → use cases (domain/use_cases/)
  → services (data/services/) → SupabaseClient
```
- Widgets: UI only. No Supabase calls, no business logic.
- Providers: state + orchestration. Use `ref.read` in methods, `ref.watch` in build.
- Use cases: single-responsibility, injectable via constructor.
- Services: raw Supabase queries. Constructor-injected `SupabaseClient`.
- No cross-feature imports except via shared `core/utilities/` or `core/models/`.

## Feature Structure
```
lib/core/features/<feature>/
  data/     → dtos/, mappers/, services/, storables/, providers/
  domain/   → models/, use_cases/, providers/, hooks/, contracts/, enums/
lib/presentation/pages/<page>/
  <page>_routable.dart   (route definition)
  <page>_page.dart       (entry widget)
  views/, components/, hooks/
```

## Active Features
auth, post, profile, connection, lockout, notification, calendar, onboarding,
media, media_picker, permission, share, startup, storage, supabase, timezone, crashlytics

## Environment Map
```
local dev  → supabase start (local Docker)    → stage Flutter flavor
staging    → goback-stage Supabase project    → stage Flutter flavor  → TestFlight internal
production → tvrbqsvxfpyfxvbypvtb (Supabase) → production flavor     → App Store
```

Branch strategy:
- `feature/*`, `fix/*` → PR to `develop`
- `develop` → staging (auto-build on push)
- `develop` → PR to `main` → production (manual approval, /promote command)

## Data Flow: Post Creation
```
PostCreationPage → CreatePostUseCase → PostRepositoryContract
  → PostCrudService.createDraftPost() → supabase.from('posts').insert()
  → PostMediaUploadService → Supabase Storage
  → PostCrudService.publishPost() → supabase.from('posts').update(published_at)
```

## Data Flow: Lockout
```
LockoutSetupPage → ManualLockoutNotifier.setLockout()
  → LockoutSessionService.createSession() → supabase RPC
  → SetManualLockoutUseCase → ManualLockoutStorable (local)
  → LockoutLiveActivityService (iOS Live Activity)
  → ScheduledNotificationProvider
```

## Key Supabase Tables (known)
`posts`, `post_media`, `post_tags`, `lockout_sessions`, `profiles`, `connections`

## Edge Functions
- `send-push-notification` — FCM v1 push delivery
- `send-lockout-notification` — lockout-specific push

## GitHub Secrets Required for CI
```
# Supabase
SUPABASE_ACCESS_TOKEN
SUPABASE_STAGE_PROJECT_REF
SUPABASE_PROD_PROJECT_REF=tvrbqsvxfpyfxvbypvtb

# iOS
APP_STORE_CONNECT_API_KEY_ID
APP_STORE_CONNECT_API_ISSUER_ID
APP_STORE_CONNECT_API_KEY_CONTENT   # base64 .p8 file
MATCH_PASSWORD                       # if using Fastlane Match
KEYCHAIN_PASSWORD

# Android
GOOGLE_PLAY_JSON_KEY                 # service account JSON, base64
ANDROID_KEYSTORE_BASE64
ANDROID_KEY_ALIAS
ANDROID_STORE_PASSWORD
ANDROID_KEY_PASSWORD

# Firebase (for crash reporting in CI)
FIREBASE_APP_ID_IOS_STAGE
FIREBASE_APP_ID_ANDROID_STAGE
```
