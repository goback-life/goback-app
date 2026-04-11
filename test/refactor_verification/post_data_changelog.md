## Post Data Layer - Refactoring Changelog

### Summary
- Reduced post_service.dart from 522 lines to 488 lines (under 500-line lint limit)
- Moved inline Supabase calls from PostService into PostCrudService for proper layering
- Removed dead code from PostCrudService
- Simplified redundant logic and cleaned up imports
- Removed 4 dead code files (PostExclusionDto + generated files, duplicate post_exception.dart)

---

### Changes by File

#### 1. `lib/core/features/post/data/services/post_service.dart`
- **Removed**: 20-line doc comment blocks on `createDraftPost` and `getFeedPosts` (duplicated info from sub-service docs)
- **Changed**: `updatePost()` now delegates to `_crudService.updatePostData()` instead of inline `supabaseClient.from('posts').update(...)`
- **Changed**: `updatePost()` now delegates to `_crudService.deletePostMediaRecords()` instead of inline `supabaseClient.from('post_media').delete()`
- **Changed**: `updatePost()` now delegates to `_crudService.deletePostTagRecords()` instead of inline `supabaseClient.from('post_tags').delete()`
- **Changed**: `updatePost()` now delegates to `_crudService.getPostField()` instead of inline `supabaseClient.from('posts').select('thumbnail_url')`
- **Why**: File was over 500-line lint limit; inline Supabase calls violated architecture boundary (service should delegate to crud service)
- **Risk**: LOW - all changes are mechanical delegations with identical Supabase queries
- **Line count**: 522 -> 488

#### 2. `lib/core/features/post/data/services/post_crud_service.dart`
- **Added**: `updatePostData(postId, updateData)` - generic post update with arbitrary fields
- **Added**: `deletePostMediaRecords(postId)` - deletes post_media records
- **Added**: `deletePostTagRecords(postId)` - deletes post_tags records
- **Added**: `getPostField(postId, field)` - fetches a single field from posts table
- **Removed**: Dead `updatePost({...})` method (lines 163-201) - never called, replaced by `updatePostData`
- **Removed**: Dead `hidePost(postId)` method (lines 224-229) - never called (PostService.hidePost uses RPC)
- **Removed**: Trailing blank line before closing brace
- **Why**: Dead code removal; new methods extracted from PostService inline calls
- **Risk**: LOW

#### 3. `lib/core/features/post/data/services/post_query_service.dart`
- **Removed**: Unused `import 'dart:async'`
- **Simplified**: No-op `try { ... } catch (e) { rethrow; }` block in `getFeedPosts()` replaced with direct call
- **Simplified**: `late dynamic feedResponse` replaced with `final` variable
- **Why**: Unused import; no-op error handling pattern
- **Risk**: LOW

#### 4. `lib/core/features/post/data/dtos/post_creation_dto.dart`
- **Simplified**: `isValid` getter - both branches of `if (isEditing)` were identical, collapsed to single path
- **Why**: Code duplication (editing and non-editing paths had same logic)
- **Risk**: LOW

#### 5. `lib/core/features/post/data/services/post_enrichment_service.dart`
- **Removed**: Trailing blank line before closing brace
- **Why**: Whitespace cleanup
- **Risk**: NONE

---

### Dead Code Removed (by agent-10)

#### 6. `lib/core/features/post/data/dtos/post_exclusion_dto.dart` (DELETED)
- Also deleted: `post_exclusion_dto.freezed.dart`, `post_exclusion_dto.g.dart`
- **Why**: Zero imports anywhere in codebase. Exclusions migrated to UUID[] array on posts table.
- **Risk**: NONE - verified via grep: `PostExclusionDto` only appears in its own file

#### 7. `lib/core/features/post/data/exceptions/post_exception.dart` (DELETED)
- **Why**: Exact duplicate of `domain/exceptions/post_exception.dart`. Zero imports of the data version.
- **Risk**: NONE - verified via grep: no file imports `data/exceptions/post_exception`

---

### Files NOT Touched
- All DTOs except post_creation_dto.dart (no changes needed)
- All mappers (no changes needed)
- All exceptions except post_exception.dart (no changes needed)
- post_repository.dart (clean at 255 lines, no issues found)
- Provider files (clean, no issues found)
- post_media_upload_service.dart (clean)
- post_media_delete_service.dart (clean)
- post_reaction_service.dart (clean)
- post_report_service.dart (clean)

---

### Verification Commands
```bash
fvm flutter analyze
fvm dart run build_runner build --delete-conflicting-outputs
```
