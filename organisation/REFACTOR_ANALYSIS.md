# Goback App: Codebase Analysis & Refactor Guide

*Generated: January 2026*

Use this document as context when starting fresh implementation work.

---

## Current Codebase Assessment

### Strengths (What Works Well)

| Component | Score | Notes |
|-----------|-------|-------|
| **Architecture** | 8.5/10 | Clean data/domain/presentation separation across all 17 features |
| **Lockout Feature** | 9/10 | Production-ready, proper use cases, join feature works, `isLockoutPost` flag in DB |
| **Code Generation** | 9/10 | 57 Freezed models, 133 Riverpod providers, no hand-written JSON |
| **Supabase Layer** | 9/10 | Unified `SupabaseResultProcessor` mixin handles all error types |
| **Result Pattern** | 9/10 | 228 files return `Result<T>` instead of throwing |
| **Connection System** | 8.5/10 | Atomic transactions, 150-limit enforced, invite codes work |
| **Internal Packages** | 8.5/10 | 12 dedecube_* packages (router, storage, logger, forms, themes) |

### Weaknesses (What Needs Work)

| Component | Score | Issue |
|-----------|-------|-------|
| **Test Coverage** | 0/10 | Zero tests exist |
| **Feed Performance** | 6/10 | Complex RPC with heavy JOINs, sequential avatar fetching |
| **Notifications** | 4/10 | Model/DTO exist but triggers and push service missing |
| **Large Files** | 6/10 | `full_screen_image.dart` (934 lines), `post_service.dart` (536 lines) |
| **Debug Statements** | - | 7 print statements in `home_view.dart` violate linting |

---

## What To Keep

### Lockout Feature (lib/core/features/lockout/)
Fully functional with:
- `ManualLockoutStorable` - Local persistence of lockout timestamps
- 5 use cases: Check, GetRemainingTime, Set, Join, Clear
- `ManualLockoutNotifier` - Riverpod async notifier
- Join lockout validates via `is_lockout_post` DB flag
- Auto-creates announcement posts with proper duration formatting

### Connection/Friends System (lib/core/features/connection/)
- Invite code generation with 72h expiry
- `join_circle_transaction()` atomic RPC
- Bidirectional edge storage
- 150 connection limit enforced
- `isUserConnected()` helper functions

### Auth System (lib/core/features/auth/)
- OTP-based via Supabase Auth
- Specialized exception mappers per operation
- Session management with refresh

### Profile System (lib/core/features/profile/)
- Simple CRUD, avatar upload
- Username uniqueness validation
- Phone number storage

### Internal Packages (packages/dedecube_*)
All 12 packages are reusable:
- `dedecube_router` - Freezed-based routing with middleware
- `dedecube_storage` - Persistent storage abstraction
- `dedecube_core` - Result pattern, contracts, utilities
- `dedecube_presentation` - Loading overlays, hooks
- `dedecube_logger` - Logging abstraction
- Others: environment, form, translator, themify, startup, custom_lints

---

## What To Remove/Simplify

- `time_limit/` feature - Replace with lockout system
- Non-lockout post types - Simplify to lockout posts only
- `link_preview/` - Incomplete and not needed
- Complex feed pagination - Simpler when only showing lockout posts

---

## Database Schema Recommendations

### Current Tables Worth Keeping
- `profiles` - User data
- `posts` - Content with `is_lockout_post` flag
- `post_media` - Media attachments
- `connections` - Friend relationships
- `invite_codes` - Invite system

### New Table Needed
```sql
CREATE TABLE lockout_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ends_at TIMESTAMPTZ NOT NULL,
  post_id UUID REFERENCES posts(id), -- linked post created on return
  participants UUID[], -- users who joined this lockout
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_lockout_sessions_active
ON lockout_sessions(user_id, ends_at)
WHERE post_id IS NULL;
```

### Feed Simplification
Current `get_user_feed()` RPC is complex. For lockout-only posts:
```sql
-- Add WHERE clause: is_lockout_post = true
-- Remove: parent_id handling (no replies)
-- Remove: post_exclusions logic (simpler privacy model)
```

---

## Screen Time API Integration (iOS)

### Required Components
1. **Apple Entitlement**: `com.apple.developer.family-controls`
2. **Native Swift Module**: Uses `FamilyControls` and `DeviceActivityMonitor`
3. **Flutter Bridge**: `MethodChannel` connecting Dart to Swift

### Suggested Architecture
```
lib/core/features/screentime/
├── data/
│   └── services/screentime_service.dart  # MethodChannel calls
├── domain/
│   ├── models/blocked_app_model.dart
│   ├── providers/screentime_notifier.dart
│   └── use_cases/
│       ├── start_blocking_use_case.dart
│       └── stop_blocking_use_case.dart

ios/Runner/
├── ScreenTimeManager.swift    # FamilyControls implementation
└── ScreenTimeBridge.swift     # MethodChannel handler
```

### Android Alternative
No clean equivalent to Screen Time API. Options:
- "Soft lockout" with social accountability (posts show you're locked out)
- Fullscreen overlay when app opened during lockout
- Consider making app blocking iOS-exclusive feature

---

## Key Patterns To Follow

### 1. Feature Structure
```
lib/core/features/<feature>/
├── data/
│   ├── dtos/           # Data Transfer Objects (Freezed + JSON)
│   ├── mappers/        # DTO ↔ Model transformations
│   ├── services/       # Supabase calls, return Result<T>
│   └── exception_handlers/
├── domain/
│   ├── models/         # Freezed immutable models
│   ├── use_cases/      # Single-responsibility business logic
│   ├── providers/      # Riverpod notifiers
│   └── hooks/          # React-style hooks
```

### 2. Result Pattern
```dart
// All async operations return Result<T>, never throw
final result = await service.doSomething();
result.fold(
  (value) => handleSuccess(value),
  (error) => handleError(error),
);
```

### 3. Supabase Service Pattern
```dart
class SomeService with SupabaseResultProcessor {
  Future<Result<Model>> fetch() => processSupabaseCall(
    () async {
      final response = await supabase.from('table').select();
      return mapper.toModel(response);
    },
    exceptionMapper: SomeExceptionMapper(),
  );
}
```

### 4. Provider Pattern (Riverpod)
```dart
@Riverpod(keepAlive: false)
class SomeNotifier extends _$SomeNotifier {
  @override
  Future<SomeModel> build() async {
    // Initial state loading
  }

  Future<void> doAction() async {
    // Update state
  }
}
```

---

## Scalability Tips

### 1. Feed Performance
- Move avatar URL fetching to parallel (currently sequential)
- Consider caching signed URLs with TTL
- Simplify `get_user_feed()` RPC for lockout-only posts

### 2. Polling
- Current: 15s intervals in `use_feed_posts.dart`
- Consider: Supabase Realtime subscriptions for lockout events
- Or: Push notifications when friends start lockouts (instead of polling)

### 3. Media Handling
- Already uses `flutter_image_compress`
- Add: Video compression before upload
- Consider: Progressive image loading

### 4. State Management
- Some providers use `keepAlive: true` - audit for memory
- Implement explicit cache invalidation for large lists

---

## Files That Need Refactoring

| File | Lines | Issue |
|------|-------|-------|
| `full_screen_image.dart` | 934 | Far exceeds 500-line limit, extract components |
| `post_service.dart` | 536 | Split into smaller focused services |
| `home_view.dart` | 497 | Remove debug prints, near limit |
| `home_feed_post_card.dart` | 477 | Consider extraction |
| `use_feed_posts.dart` | 396 | Complex polling logic |

---

## Implementation Priority Order

1. **Infrastructure First**
   - Add test coverage for lockout feature
   - Complete notification system (triggers + push)
   - Create `lockout_sessions` table

2. **iOS Screen Time**
   - Apply for Apple entitlement
   - Build native Swift module
   - Create Flutter bridge

3. **Feed Simplification**
   - Modify RPC for lockout posts only
   - Remove non-lockout post creation
   - Add network notification on lockout start

4. **Profile Calendar**
   - Calendar view of lockout history
   - Query posts by date where `is_lockout_post = true`

5. **Polish**
   - Break down large files
   - Full test coverage
   - Performance optimization

---

## Why Refactor > Rebuild

- 57 Freezed models would need recreation
- 133 Riverpod providers already working
- 12 dedecube_* packages are reusable
- Unified Supabase error handling exists
- Lockout feature is already production-ready
- CLAUDE.md provides AI-readable patterns

**Estimated time: 6-8 weeks (refactor) vs. 12-16 weeks (rebuild)**

---

## Quick Reference: Feature Locations

| Feature | Location |
|---------|----------|
| Lockout | `lib/core/features/lockout/` |
| Auth | `lib/core/features/auth/` |
| Posts | `lib/core/features/post/` |
| Profile | `lib/core/features/profile/` |
| Connections | `lib/core/features/connection/` |
| Notifications | `lib/core/features/notification/` |
| Feed | `lib/presentation/pages/home/` |
| Supabase Config | `lib/core/features/supabase/` |
