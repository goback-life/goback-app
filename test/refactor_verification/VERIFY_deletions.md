# Dead Code Deletion Verification Report

**Date:** 2026-03-20
**Auditor:** verify-02-deletions agent

---

## Connection Feature Deletions

### 1. `lib/core/features/connection/data/dtos/connection_dto.dart`
**Command:** `grep pattern "connection_dto" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 2. `lib/core/features/connection/data/dtos/invite_code_dto.dart`
**Command:** `grep pattern "invite_code_dto" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 3. `lib/core/features/connection/data/dtos/profile_dto.dart`
**Command:** `grep pattern "profile_dto" in lib/**/*.dart` (also checked `connection/data/dtos/profile_dto` specifically)
**Results:** No files found (no imports of the connection-specific profile_dto path)
**Verdict:** PASS

### 4. `lib/core/features/connection/data/exceptions/invite_code_expired_exception.dart`
**Command:** `grep pattern "invite_code_expired_exception" in lib/**/*.dart`
**Results:** Found 3 files:
- `lib/core/features/connection/data/services/connection_service.dart`
- `lib/core/features/connection/data/mappers/validate_invite_code_exceptions_mapper.dart`
- `lib/core/features/connection/data/mappers/join_circle_exceptions_mapper.dart`

**Investigation:** All 3 files import from `domain/exceptions/invite_code_expired_exception.dart`, NOT `data/exceptions/invite_code_expired_exception.dart`. The domain version still exists at `lib/core/features/connection/domain/exceptions/invite_code_expired_exception.dart`. The deleted file was the `data/exceptions/` copy.
**Verdict:** PASS - The `data/exceptions/` version was unused; all imports reference the `domain/exceptions/` version which still exists.

### 5. `lib/core/features/connection/data/mappers/connection_dto_to_model_mapper.dart`
**Command:** `grep pattern "connection_dto_to_model_mapper" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 6. `lib/core/features/connection/data/mappers/invite_code_dto_to_model_mapper.dart`
**Command:** `grep pattern "invite_code_dto_to_model_mapper" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 7. `lib/core/features/connection/data/mappers/profile_dto_to_model_mapper.dart`
**Command:** `grep pattern "profile_dto_to_model_mapper" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 8. `lib/core/features/connection/domain/models/invite_code_model.dart`
**Command:** `grep pattern "invite_code_model" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 9. `lib/core/features/connection/domain/use_cases/get_circle_members_use_case.dart`
**Command:** `grep pattern "get_circle_members_use_case" in lib/**/*.dart`
**Results:** No files found (note: "get_circle_members" has 30 references, but all refer to providers, DTOs, repositories, and other files -- NOT the deleted use_case file)
**Verdict:** PASS

---

## Post Feature Deletions

### 10. `lib/core/features/post/data/dtos/post_exclusion_dto.dart`
**Command:** `grep pattern "post_exclusion_dto" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 11. `lib/core/features/post/data/exceptions/post_exception.dart`
**Command:** `grep pattern "data/exceptions/post_exception" in lib/**/*.dart`
**Results:** No matches found (the 9 files matching "post_exception" reference domain exceptions or other specific exception files, not the deleted `data/exceptions/post_exception.dart`)
**Verdict:** PASS

### 12. `lib/core/features/post/domain/hooks/use_feed_posts/feed_posts_actions.dart`
**Command:** `grep pattern "feed_posts_actions" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 13. `lib/core/features/post/domain/hooks/use_feed_posts/feed_posts_polling.dart`
**Command:** `grep pattern "feed_posts_polling" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

---

## Other Deletions

### 14. `lib/core/features/media/domain/enums/image_source.dart`
**Command:** `grep pattern "image_source" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 15. `lib/core/features/permission/data/exceptions/storage_permission_denied_exception.dart`
**Command:** `grep pattern "storage_permission_denied" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 16. Orphaned .g.dart files in time_limit/
**Command:** Glob for `lib/**/time_limit/**/*.dart` and `lib/presentation/pages/time_limit_reached/*.dart`
**Results:** Found 2 orphaned generated files:
- `lib/presentation/pages/time_limit_reached/time_limit_reached_routable.g.dart`
- `lib/presentation/pages/time_limit_reached/time_limit_reached_routable.freezed.dart`

The source file `time_limit_reached_routable.dart` does NOT exist. These generated files are `part of` a non-existent file. No other file imports them.
**Verdict:** PASS (not harmful, but NOTE: these orphaned generated files should be cleaned up)

---

## Dead Methods Removed

### 17. `_parseJsonbArray` in notification_service.dart
**Command:** `grep pattern "_parseJsonbArray" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 18. `fromRpcJson` in aggregated_notification_dto.dart
**Command:** `grep pattern "fromRpcJson" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 19. `updatePostType` in post_creation_notifier_provider.dart
**Command:** `grep pattern "updatePostType" in lib/**/*.dart`
**Results:** No files found
**Verdict:** PASS

### 20. `updatePost()` and `hidePost()` in post_crud_service.dart
**Commands:**
- `grep pattern "updatePost\b" in lib/**/*.dart` -- Found 8 files
- `grep pattern "hidePost" in lib/**/*.dart` -- Found 9 files

**Investigation:** Read `post_crud_service.dart` (219 lines). It contains `updatePostData()` and `updatePostThumbnail()` but does NOT contain `updatePost()` or `hidePost()`. The references found are in the proper service chain (`post_service.dart`, `post_repository.dart`, use cases, providers, contracts) -- these are live methods in the active architecture, NOT in `post_crud_service.dart`.
**Verdict:** PASS - The methods `updatePost()` and `hidePost()` were correctly removed from `post_crud_service.dart` only; the service chain methods remain intact.

### 21. `mapDtoList` override in lockout_session_dto_to_model_mapper.dart
**Command:** `grep pattern "mapDtoList" in lib/core/features/lockout/**/*.dart`
**Results:** 1 caller: `lib/core/features/lockout/domain/providers/friends_locked_out_cache_provider.dart` line 112

**Investigation:** Read the mapper file -- it no longer contains a `mapDtoList` override. Read the base class `DtoToModelMapperContract` -- it provides a default `mapDtoList` implementation at line 11: `List<Model> mapDtoList(List<Dto> dtos) => dtos.map(mapDto).toList();`. The caller invokes `_mapper.mapDtoList(dtos)` which will resolve to the base class implementation.
**Verdict:** PASS - Removing the redundant override is safe; the base class provides the same behavior.

### 22. 6 unused layout values in publish_content_layout.dart
**Command:** `grep pattern "PublishContentLayout" in lib/**/*.dart`
**Results:** 4 files use the mixin. Read the layout file -- it now has 6 values (4 overrides from MainLayout + 2 custom: `titleToImage`, `membersListSearchToList`). Both custom values are actively referenced in `publish_content_view.dart` and `publish_content_page.dart`.
**Verdict:** PASS - The 6 removed values have zero remaining references. The 2 retained custom values are actively used.

---

## Summary

| Item | File/Method | Verdict |
|------|-------------|---------|
| 1  | connection_dto.dart | PASS |
| 2  | invite_code_dto.dart | PASS |
| 3  | profile_dto.dart (connection) | PASS |
| 4  | invite_code_expired_exception.dart (data/) | PASS |
| 5  | connection_dto_to_model_mapper.dart | PASS |
| 6  | invite_code_dto_to_model_mapper.dart | PASS |
| 7  | profile_dto_to_model_mapper.dart (connection) | PASS |
| 8  | invite_code_model.dart | PASS |
| 9  | get_circle_members_use_case.dart | PASS |
| 10 | post_exclusion_dto.dart | PASS |
| 11 | post_exception.dart (data/) | PASS |
| 12 | feed_posts_actions.dart | PASS |
| 13 | feed_posts_polling.dart | PASS |
| 14 | image_source.dart | PASS |
| 15 | storage_permission_denied_exception.dart | PASS |
| 16 | Orphaned .g.dart in time_limit | PASS (note: cleanup recommended) |
| 17 | _parseJsonbArray | PASS |
| 18 | fromRpcJson | PASS |
| 19 | updatePostType | PASS |
| 20 | updatePost()/hidePost() in crud service | PASS |
| 21 | mapDtoList override in lockout mapper | PASS |
| 22 | 6 unused layout values | PASS |

**Overall Result: 22/22 PASS**

All deleted files and removed methods were confirmed to have zero live references in the codebase. No breaking deletions detected.

**Note:** 2 orphaned generated files exist at `lib/presentation/pages/time_limit_reached/` (item 16) that should be cleaned up but are non-breaking.
