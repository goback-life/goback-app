/// Post Data Layer - Behavioral Specification (Pre-Refactor)
///
/// This file documents the current behavior contracts of the post data layer
/// before any refactoring changes. It serves as a verification reference.
///
/// Generated: 2026-03-20

// =============================================================================
// FILE CATALOG
// =============================================================================
//
// SERVICES (7 files):
//   post_service.dart (488 lines) - Facade delegating to sub-services
//   post_crud_service.dart (219 lines) - CRUD operations on posts table
//   post_enrichment_service.dart (80 lines) - Signed URL enrichment
//   post_media_delete_service.dart (63 lines) - Media file deletion
//   post_media_upload_service.dart (95 lines) - Media file upload
//   post_query_service.dart (112 lines) - Feed queries with enrichment
//   post_reaction_service.dart (102 lines) - Reaction CRUD
//   post_report_service.dart (57 lines) - Report check/create
//
// DTOs (8 files, 7 with generated code):
//   feed_post_dto.dart - Feed post DTO (freezed + json)
//   feed_response_dto.dart - Paginated feed response (freezed + json)
//   post_dto.dart - Core post DTO (freezed + json)
//   post_creation_dto.dart - Post creation form data (freezed only, no json)
//   post_media_dto.dart - Media entry DTO (freezed + json)
//   post_reaction_dto.dart - Reaction DTO (freezed + json)
//   post_report_dto.dart - Report DTO (freezed + json)
//   post_tag_dto.dart - Tag DTO with PostTagType enum (freezed + json)
//   [REMOVED] post_exclusion_dto.dart - was dead code (exclusions migrated to UUID[] on posts)
//
// MAPPERS (6 files):
//   create_post_exception_mapper.dart - Maps Supabase exceptions for create/update/delete
//   feed_post_exception_mapper.dart - Maps Supabase exceptions for feed queries
//   feed_post_dto_to_model_mapper.dart - FeedPostDto -> FeedPostModel
//   feed_response_dto_to_model_mapper.dart - FeedResponseDto -> FeedResponseModel
//   post_dto_to_model_mapper.dart - PostDto -> PostModel
//   post_reaction_dto_to_model_mapper.dart - PostReactionDto -> PostReactionModel
//   post_report_dto_to_model_mapper.dart - PostReportDto -> PostReportModel
//
// EXCEPTIONS (7 files):
//   create_post_failed_exception.dart - Fallback for create failures
//   feed_post_anauthorized_exceptions.dart - Auth errors on feed (typo in filename)
//   feed_post_fetch_exceptions.dart - Generic feed fetch failures
//   feed_post_network_exceptions.dart - Network errors on feed
//   post_rate_limit_exception.dart - Rate limit exceeded
//   post_report_exception.dart - Report operation failures
//   post_upload_failed_exception.dart - Upload failures
//   [REMOVED] post_exception.dart - was dead duplicate of domain/exceptions/post_exception.dart
//
// REPOSITORIES (1 file):
//   post_repository.dart (255 lines) - Orchestrates service + mappers + result pattern
//
// PROVIDERS (2 files):
//   post_service_provider.dart - Riverpod provider for PostService
//   post_repository_provider.dart - Riverpod provider for PostRepository
//

// =============================================================================
// PUBLIC API CONTRACTS
// =============================================================================

// --- PostService (implements PostServiceContract) ---
// Constructor: PostService({required SupabaseClient supabaseClient, required Ref ref})
//
// Methods (all @override from PostServiceContract):
//   createPostWithMedia({authorId, contentType, mediaFiles, publishedTimezone, description?, thumbnailFile?, lockoutId?, excludedUserIds?}) -> Future<PostDto>
//   uploadMediaFiles(userId, mediaFiles, contentType, [postId]) -> Future<List<String>>
//   createDraftPost({authorId, contentType, thumbnailUrl, thumbnailWidth, thumbnailHeight, description?, lockoutId?, excludedUserIds?}) -> Future<PostDto>
//   addPostMedia({postId, mediaUrls, contentType}) -> Future<List<PostMediaDto>>
//   addPostTags({postId, taggedUserIds}) -> Future<List<PostTagDto>>
//   setPostExclusions({postId, excludedUserIds}) -> Future<void>
//   publishPost(postId) -> Future<PostDto>
//   updatePost({postId, description, taggedUserIds, excludedUserIds, authorId, contentType, newMediaFile?, newThumbnailFile?}) -> Future<PostDto>
//   deletePost({postId, authorId}) -> Future<void>
//   hidePost({postId, userId}) -> Future<void>
//   hasUserReportedPost({postId, userId}) -> Future<bool>
//   createReport({postId, userId, reason}) -> Future<PostReportDto>
//   getFeedPosts({userId, pageSize=15, cursor?}) -> Future<FeedResponseDto>
//   getPostById({postId}) -> Future<FeedPostDto>
//   getPostReactions({postId}) -> Future<List<PostReactionDto>>
//   addReaction({postId, userId, reaction}) -> Future<PostReactionDto>
//   deleteReaction({reactionId}) -> Future<void>
//
// Private:
//   _deletePost(postId) -> Future<void>  [cleanup on failed create]

// --- PostRepository (implements PostRepositoryContract, with SupabaseResultProcessor) ---
// Constructor: PostRepository({postService, postMapper, feedResponseMapper, feedPostMapper})
//
// Methods:
//   createPost(PostDataModel) -> FutureResult<PostModel>
//   updatePost(PostDataModel) -> FutureResult<PostModel>
//   getFeedPosts({userId, pageSize=15, cursor?}) -> FutureResult<FeedResponseModel>
//   getPostById({postId}) -> FutureResult<FeedPostModel>
//   deletePost({postId, authorId}) -> FutureResult<void>
//   hidePost({postId, userId}) -> FutureResult<void>
//   reportPost({postId, userId, reason}) -> FutureResult<PostReportModel>
//   getPostReactions({postId}) -> FutureResult<List<PostReactionModel>>
//   addReaction({postId, userId, reaction}) -> FutureResult<PostReactionModel>
//   deleteReaction({reactionId}) -> FutureResult<void>

// --- PostCrudService ---
// Constructor: PostCrudService(SupabaseClient)
//
// Methods:
//   createDraftPost({authorId, contentType, thumbnailUrl, thumbnailWidth, thumbnailHeight, description?, lockoutId?, excludedUserIds?}) -> Future<PostDto>
//   addPostMedia({postId, mediaUrls, contentType, durationSeconds?}) -> Future<List<PostMediaDto>>
//   addPostTags({postId, taggedUserIds, tagType='mention'}) -> Future<List<PostTagDto>>
//   addParticipantTags({postId, participantUserIds}) -> Future<List<PostTagDto>>
//   setPostExclusions({postId, excludedUserIds}) -> Future<void>
//   publishPost(postId) -> Future<PostDto>
//   updatePostData(postId, updateData) -> Future<PostDto>  [replaces dead updatePost]
//   deletePostMediaRecords(postId) -> Future<void>  [extracted from PostService]
//   deletePostTagRecords(postId) -> Future<void>  [extracted from PostService]
//   getPostField(postId, field) -> Future<Map<String, dynamic>>  [extracted from PostService]
//   updatePostThumbnail(postId, thumbnailUrl) -> Future<PostDto>
//   deletePost(postId) -> Future<void>

// =============================================================================
// DEAD CODE - RESOLVED
// =============================================================================
//
// 1. [REMOVED] PostExclusionDto (post_exclusion_dto.dart + generated files)
//    Exclusions migrated to UUID[] array on posts table. No imports found.
//
// 2. [REMOVED by agent-01] PostCrudService.updatePost() - never called
//    Replaced by PostCrudService.updatePostData() which is used by PostService.
//
// 3. [REMOVED by agent-01] PostCrudService.hidePost() - never called
//    PostService.hidePost() uses RPC 'hide_post_for_user' directly.
//
// 4. [REMOVED] data/exceptions/post_exception.dart
//    Was exact duplicate of domain/exceptions/post_exception.dart.

// =============================================================================
// CROSS-FILE DEPENDENCIES (imports FROM outside this layer)
// =============================================================================
//
// External dependencies INTO this layer:
//   - domain/contracts/post_service_contract.dart (PostService implements)
//   - domain/contracts/post_repository_contract.dart (PostRepository implements)
//   - domain/enums/content_type.dart (used by services, mappers)
//   - domain/models/* (PostModel, FeedPostModel, etc. - used by mappers, repository)
//   - domain/exceptions/post_exception.dart (used by create_post_exception_mapper)
//   - domain/exceptions/feed_post_exceptions.dart (base for feed exceptions)
//   - core/exceptions/main_exception.dart (base for all exceptions)
//   - core/exceptions/unhandled_exception.dart (used in mappers)
//   - core/mappers/dto_to_model_mapper_contract.dart (mapper base)
//   - supabase/data/mixins/supabase_result_processor.dart (repository mixin)
//   - supabase/data/providers/supabase_client_provider.dart (provider)
//   - supabase/utilities/supabase_buckets.dart (bucket constants)
//   - storage/data/providers/signed_url_provider.dart (enrichment)
//   - media/domain/exceptions/invalid_media_exception.dart (create mapper)
//   - core/utilities/video_thumbnail_helper.dart (service)
//
// This layer exports to:
//   - domain/hooks/use_post_creation.dart imports PostCreationDto
//   - domain/providers/post_creation_notifier_provider.dart imports PostCreationDto

// =============================================================================
// RESOLVED: post_service.dart NOW AT 488 LINES (UNDER 500 LIMIT)
// =============================================================================
//
// agent-01 reduced from 522 to 488 lines by:
//   - Removing doc comments (~20 lines)
//   - Delegating inline Supabase calls to PostCrudService methods
//   - Replacing inline post_media/post_tags delete with _crudService methods
//   - Replacing inline posts select/update with _crudService methods
//
// agent-10 additionally removed:
//   - PostExclusionDto (dead DTO + 2 generated files) = 3 files removed
//   - data/exceptions/post_exception.dart (dead duplicate) = 1 file removed
