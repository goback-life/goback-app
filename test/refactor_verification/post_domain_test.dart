/// Verification test documenting the current behavior contracts
/// of lib/core/features/post/domain/
///
/// This file catalogs all public APIs, their signatures, and cross-file
/// dependencies to ensure refactoring preserves all contracts.

// =============================================================================
// MODELS (Freezed)
// =============================================================================
//
// FeedCacheState (feed_cache_state.dart)
//   Fields: posts, lastFetchedAt, oldestPostTimestamp, newestPostTimestamp,
//           hasNextPage, isPreloading, backgroundLoadingCount,
//           initialLoadComplete, fullyLoaded
//   Used by: FeedPostsCache provider, useFeedPosts hook
//
// FeedPostModel (feed_post_model.dart)
//   Fields: id, authorId, publishedAt, publishedTimezone, createdAt, updatedAt,
//           taggedUsernames, taggedUserIds, excludedUserIds, thumbnailWidth,
//           thumbnailHeight, contentType, isAuthorConnected, authorUsername?,
//           imageUrl?, videoUrl?, authorAvatarUrl?, description?, lockoutId?,
//           lockoutScore?, lockoutDurationMinutes?, calendarSavedAt?,
//           linkPreviews, reactionCount, commentCount
//   Methods: isLockoutPost, lockoutDurationFormatted, localPublishedAt(ref)
//   Used by: Almost all feed/post files
//
// FeedResponseModel (feed_response_model.dart)
//   Fields: posts, totalCount, hasNextPage
//   Used by: getFeedPostsProvider, GetFeedPostsUseCase
//
// LinkPreviewModel (link_preview_model.dart) -- plain class, NOT freezed
//   Fields: url, title?, description?, imageUrl?, siteName?
//   Used by: FeedPostModel.linkPreviews
//
// MediaItemModel (media_item_model.dart)
//   Fields: id, mediaType, mediaUrl, sortOrder
//   Used by: PostModel.mediaItems
//
// ParentPostReferenceModel (parent_post_reference_model.dart)
//   Fields: id, authorUsername, thumbnailUrl, thumbnailWidth, thumbnailHeight,
//           contentType, authorId?, isDeleted
//   Used by: ParentPostReferenceNotifier, usePostCreationInitialization
//
// PostActionEvent (post_action_event.dart)
//   Fields: action (PostActionType), timestamp, postId?
//   Used by: PostActionNotifier, useFeedPosts
//
// PostDataModel (post_data_model.dart)
//   Fields: authorId, contentType, mediaFiles, publishedTimezone, postId?,
//           description?, thumbnailFile?, taggedUserIds, excludedUserIds, lockoutId?
//   Used by: createPostProvider, updatePostProvider, use cases
//
// PostModel (post_model.dart)
//   Fields: id, authorId, contentType, thumbnailUrl, thumbnailWidth,
//           thumbnailHeight, status, createdAt, updatedAt, publishedAt,
//           publishedTimezone, description?, lockoutId?, calendarSavedAt?, mediaItems
//   Methods: isLockoutPost, localPublishedAt(ref)
//   Enum: PostStatus { draft, published, failed }
//   Used by: usePostCreation, createPostProvider, updatePostProvider
//
// PostReactionModel (post_reaction_model.dart)
//   Fields: id, postId, userId, reaction, createdAt, updatedAt
//   Used by: reaction providers/use cases
//
// PostReportModel (post_report_model.dart)
//   Fields: id, postId, reportedBy, reason (PostReportReason), createdAt
//   Used by: reportPostProvider, ReportPostUseCase

// =============================================================================
// ENUMS
// =============================================================================
//
// ContentType { image, audio, video, doubleImage, text }
// PostActionType { create, update, delete, hide, report }
// PostReportReason { nudity, shockingContent, hateSpeech, bullying, spam, changedMind }
//   - has .value getter and fromValue() static

// =============================================================================
// CONSTANTS
// =============================================================================
//
// TextPostConstants.maxTextPostLength = 500

// =============================================================================
// EXCEPTIONS
// =============================================================================
//
// PostException extends MainException
// FeedPostException extends MainException
// FeedPostEmptyException extends FeedPostException
// FeedPostPermissionException extends FeedPostException
// FeedPostValidationException extends FeedPostException

// =============================================================================
// CONTRACTS
// =============================================================================
//
// PostRepositoryContract (abstract)
//   - createPost, updatePost, getFeedPosts, getPostById
//   - deletePost, hidePost, reportPost
//   - getPostReactions, addReaction, deleteReaction
//
// PostServiceContract (abstract)
//   - createPostWithMedia, uploadMediaFiles, createDraftPost
//   - addPostMedia, addPostTags, setPostExclusions, publishPost
//   - updatePost, getFeedPosts, getPostById, deletePost, hidePost
//   - hasUserReportedPost, createReport
//   - getPostReactions, addReaction, deleteReaction

// =============================================================================
// PROVIDERS (Riverpod @riverpod / @Riverpod)
// =============================================================================
//
// feedPostsCacheProvider (keepAlive: true) - FeedPostsCache
//   Public methods:
//     posts (getter, filtered 24h), isInitialLoadComplete, isFullyLoaded,
//     isBackgroundLoading, hasMorePosts, currentUserId
//     loadInitialPosts(userId), loadMorePostsNow(userId, {count}),
//     refresh(userId), fetchAndAddPost(postId), checkForDeletions(userId),
//     checkForDeletionsStaggered(userId), addPost(post), updatePost(post),
//     removePost(postId), removeExpiredPosts(), invalidateCache(),
//     needsFullRebuild, fullCacheRebuild(userId), reEnrichCachedPosts(),
//     lastEnrichedAt, updateCache(posts, {hasNextPage}),
//     isCacheValid, preloadFeed(userId)
//   FILE SIZE: 563 lines -- OVER 500-LINE LINT LIMIT
//
// addReactionProvider(postId, userId, reaction) -> Future<Result<PostReactionModel>>
// createPostProvider(postData) -> Future<Result<PostModel>>
// deletePostProvider(postId, authorId) -> Future<Result<void>>
// deleteReactionProvider(reactionId) -> Future<Result<void>>
// getFeedPostsProvider(userId, {pageSize, cursor}) -> Future<Result<FeedResponseModel>>
// getPostByIdProvider(postId) -> Future<Result<FeedPostModel>>
// getPostReactionsProvider(postId) -> Future<Result<List<PostReactionModel>>>
// hidePostProvider(postId, userId) -> Future<Result<void>>
// parentPostReferenceNotifierProvider (keepAlive: true) -> ParentPostReferenceModel?
//   Methods: setParentPost(parentPost), clear()
// postActionNotifierProvider (keepAlive: true) -> PostActionEvent?
//   Methods: notifyPostCreated({postId}), notifyPostUpdated(), notifyPostDeleted(),
//            notifyPostHidden(), notifyPostReported(), clearAction()
// postCreationLockProvider (keepAlive: true) -> Set<String>
//   Methods: isLocked(userId), lock(userId), unlock(userId)
// postCreationNotifierProvider -> PostCreationDto
//   Methods: loadExistingPost(...), updateImage(image), updateFirstFrame(firstFrame),
//            updateThumbnail(thumbnail), updatePostType(postType),
//            updateContentType(contentType), updateDescription(description),
//            updateTaggedUsers(taggedUserIds), updateExcludedUsers(excludedUserIds),
//            reset()
// postPublishedNotifierProvider (keepAlive: true) -> DateTime?
//   Methods: clearPublishedFlag()
// reportPostProvider(postId, userId, reason) -> Future<Result<PostReportModel>>
// updatePostProvider(postData) -> Future<Result<PostModel>>

// =============================================================================
// USE CASES
// =============================================================================
//
// AddReactionUseCase(repository).withReactionData(postId, userId, reaction).execute()
// CreatePostUseCase(repository).withPostData(postData).execute()
// DeletePostUseCase(repository).withPostData(postId, authorId).execute()
// DeleteReactionUseCase(repository).withReactionData(reactionId).execute()
// GetFeedPostsUseCase(repository).execute(userId, {pageSize, cursor})
// GetPostReactionsUseCase(repository).withPostId(postId).execute()
// HidePostUseCase(repository).withPostData(postId, userId).execute()
// ReportPostUseCase(repository).withReportData(postId, userId, reason).execute()
// UpdatePostUseCase(repository).withPostData(postData).execute()

// =============================================================================
// HOOKS
// =============================================================================
//
// usePostCreation(ref) -> PostCreationResult
//   typedef PostCreationResult = ({
//     PostCreationDto data, File? mainImage, File? thumbnail,
//     bool isLoading, bool canPublish,
//     ValueChanged<String> updateDescription,
//     ValueChanged<List<String>> updateTaggedUsers,
//     ValueChanged<List<String>> updateExcludedUsers,
//     Future<void> Function(File) updateImage,
//     ValueChanged<File?> updateFirstFrame, ValueChanged<File?> updateThumbnail,
//     Future<Result<PostModel>?> Function() publishPost,
//     Future<Result<PostModel>?> Function(List<String>) publishPostWithExclusions,
//     VoidCallback resetCreation,
//   })
//   FILE SIZE: 291 lines -- Under limit but complex
//
// useFeedPosts(ref, {userId, targetDate?}) -> FeedPostsResult
//   typedef FeedPostsResult = ({
//     List<FeedPostModel> posts, bool isLoading, bool isLoadingMore,
//     bool hasNextPage, int newPostsCount, String? errorMessage,
//     VoidCallback loadMore, Future<void> Function() refresh,
//     VoidCallback loadNewPosts,
//   })
//
// usePostDetail({ref, postId, fallbackPost?}) -> PostDetailResult
//   typedef PostDetailResult = ({
//     FeedPostModel? post, bool isLoading, String? errorMessage,
//   })
//
// usePostReactions(ref, postId) -> PostReactionsResult
//   typedef PostReactionsResult = ({
//     AsyncValue<dynamic> reactions, bool isLoading,
//     Future<void> Function(String) addReaction,
//     Future<void> Function() removeReaction,
//     VoidCallback refresh,
//   })
//
// useMemberExclusion(ref) -> MemberExclusionResult
//   typedef MemberExclusionResult = ({
//     String searchQuery, Set<String> selectedMembers,
//     Set<String> excludedMembers, Set<String> taggedUserIds,
//     String? parentPostAuthorId,
//     Map<String, List<ProfileModel>> groupedMembers,
//     ValueChanged<String> updateSearchQuery,
//     ValueChanged<Set<String>> updateSelectedMembers,
//     void Function(String, {required bool selected}) toggleMemberSelection,
//     VoidCallback selectAll, VoidCallback deselectAll,
//     void Function(String) selectOnly,
//     void Function(List<ConnectionMemberModel>, {..}) initializeWith,
//   })
//
// useMentionAutocomplete(ref) -> MentionAutocompleteState
//   class MentionAutocompleteState { allUsers, isLoading, parseMentions }
//
// usePostCreationInitialization(ref, {parentPost?, onNavigateToEditor?,
//     loadingNotifier?, skipContentTypePicker?}) -> PostCreationInitializationResult
//   typedef PostCreationInitializationResult = ({
//     bool isInitialized, VoidCallback selectMainImage, VoidCallback resetCreation,
//   })
//
// useJoinLockoutPost(ref, lockoutDuration, otherUserId, otherUserUsername)
//   -> Future<Result<PostModel>?>

// =============================================================================
// HELPER CLASSES
// =============================================================================
//
// FeedPostsPolling (static methods)
//   - checkForNewPosts({ref, userId, posts, newestPostTimestamp, newPostsCount})
//   - checkForNewPostsForRetry({ref, userId, posts, newestPostTimestamp,
//       oldestPostTimestamp, newPostsCount})
//   - checkForNewPostsWithRetry({ref, userId, posts, newestPostTimestamp,
//       oldestPostTimestamp, newPostsCount, isMounted, maxRetries})
//   - addPostImmediately({ref, postId, userId, posts, newestPostTimestamp,
//       oldestPostTimestamp})
//   - checkForPostUpdates({ref, userId, posts})
//
// FeedPostsActions (static methods)
//   - loadOlderPosts({ref, userId, isLoading, isLoadingMore, hasNextPage,
//       posts, oldestPostTimestamp, errorMessage})
//   - loadInitialPosts({ref, userId, isLoading, posts, hasNextPage,
//       errorMessage, newPostsCount, newestPostTimestamp, oldestPostTimestamp})

// =============================================================================
// UTILITIES
// =============================================================================
//
// TextPostParser (static methods)
//   - parseMentions(text, allUsers) -> List<String>
//   - parseMarkdownLinks(text) -> List<({String alias, String url})>
//   - hasUrl(text) -> bool
//   - findUrls(text) -> List<({String url, int start, int end})>
//   - convertUrlToMarkdown(url, alias) -> String
//   - replaceUrlWithMarkdown(text, originalUrl, alias) -> String
//
// UrlShortener (static methods)
//   - shortenUrlsInText(text) -> String

// =============================================================================
// CROSS-FILE DEPENDENCY MAP
// =============================================================================
//
// feed_posts_cache_provider.dart
//   -> feed_cache_state.dart, feed_post_model.dart
//   -> get_feed_posts_provider.dart, get_post_by_id_provider.dart
//
// use_feed_posts.dart
//   -> feed_posts_cache_provider.dart, post_action_notifier_provider.dart
//   -> post_published_notifier_provider.dart, feed_post_model.dart
//   -> post_action_type.dart
//
// feed_posts_polling.dart
//   -> feed_post_model.dart, feed_posts_cache_provider.dart
//   -> get_feed_posts_provider.dart, get_post_by_id_provider.dart
//   -> unread_notification_count_provider (notification feature)
//
// feed_posts_actions.dart
//   -> feed_post_model.dart, feed_posts_cache_provider.dart
//   -> get_feed_posts_provider.dart
//
// use_post_creation.dart
//   -> auth, lockout, post data/providers, timezone (cross-feature deps)
//
// use_join_lockout_post.dart
//   -> auth, profile, post, timezone, utilities (cross-feature deps)
//
// use_member_exclusion.dart
//   -> connection feature models, profile model
//
// use_mention_autocomplete.dart
//   -> connection feature providers, profile model
//
// use_post_creation_initialization.dart
//   -> media feature hooks, post providers/enums/models, presentation layer

// =============================================================================
// KEY ISSUES IDENTIFIED
// =============================================================================
//
// 1. feed_posts_cache_provider.dart: 563 lines (OVER 500-line lint limit)
//    - Contains both cache state management and server fetch orchestration
//    - Candidate for splitting: extract server-fetch helpers
//
// 2. FeedPostsActions: Appears to be a legacy helper class used before
//    useFeedPosts was refactored to use the cache provider directly.
//    Its loadInitialPosts and loadOlderPosts work with ValueNotifier state
//    rather than the cache provider's state. May be dead code if nothing
//    imports it outside use_feed_posts/.
//
// 3. FeedPostsPolling: Similar to FeedPostsActions - uses ValueNotifier
//    pattern while useFeedPosts now uses cache provider. Must verify
//    external usage before removing.
//
// 4. Duplicate URL regex patterns: TextPostParser._urlPattern and
//    UrlShortener both define the same URL regex.
//
// 5. PostCreationNotifier.updatePostType vs updateContentType:
//    Both do the exact same thing - potential dead code.
