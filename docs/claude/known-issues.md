# Known Issues & Tech Debt

## Active TODOs
- `lib/core/features/post/data/mappers/feed_post_dto_to_model_mapper.dart`
  `linkPreviews: []  // TODO: Parse linkPreviews JSON when implemented`
  — link preview data exists in DTO but is never parsed into the model.
  Low priority until link sharing is built.

## Known Architectural Debt
- Android bundle ID is `com.example.cloudless` — placeholder, not branded.
  Needs updating to `com.goback.app` before production Android release.
  Changing this requires updating Firebase, Play Store, and signing configs.

- No migration files exist — database is managed entirely via Supabase dashboard.
  Risk: schema drift between environments is invisible until runtime.
  Fix: supabase db pull + CLI migration workflow (in progress via /new-migration command).

- Tests are refactor-verification style (20 files in test/refactor_verification/).
  Only 1 true unit test (feed_posts_cache_provider_test.dart).
  Supabase-dependent code paths have zero test coverage.

- `ManualLockoutModel` uses hand-written `copyWith` instead of Freezed.
  Works correctly but inconsistent with other models. Low priority.

## Shipped Known Issues
(updated by /deploy-beta command — log issues here when shipping with known bugs)
