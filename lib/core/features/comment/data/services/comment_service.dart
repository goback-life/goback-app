import 'package:cloudless/core/features/comment/data/dtos/post_comment_dto.dart';
import 'package:cloudless/core/features/comment/data/exceptions/comment_exceptions.dart';
import 'package:cloudless/core/features/comment/domain/contracts/comment_service_contract.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing post comments.
class CommentService implements CommentServiceContract {
  const CommentService({required this.supabase});

  final SupabaseClient supabase;

  @override
  FutureResult<List<PostCommentDto>> getPostComments({
    required String postId,
    int limit = 50,
    DateTime? cursor,
  }) async {
    try {
      var filterQuery = supabase
          .from('post_comments')
          .select('''
            id, post_id, author_id, content, created_at, deleted_at,
            profiles!author_id (username, avatar_url)
          ''')
          .eq('post_id', postId)
          .isFilter('deleted_at', null);

      if (cursor != null) {
        filterQuery = filterQuery.gt('created_at', cursor.toIso8601String());
      }

      final response = await filterQuery
          .order('created_at', ascending: true)
          .limit(limit);

      final comments = (response as List).map((json) {
        final data = json as Map<String, dynamic>;
        final profile = data['profiles'] as Map<String, dynamic>?;

        return PostCommentDto.fromJson({
          'id': data['id'],
          'post_id': data['post_id'],
          'author_id': data['author_id'],
          'author_username': profile?['username'] ?? 'Unknown',
          'author_avatar_url': profile?['avatar_url'],
          'content': data['content'],
          'created_at': data['created_at'],
          'deleted_at': data['deleted_at'],
        });
      }).toList();

      return Result.success(comments);
    } catch (e) {
      logger.error('Failed to get post comments', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to get comments: $e'),
      );
    }
  }

  @override
  FutureResult<PostCommentDto> createComment({
    required String postId,
    required String content,
    List<String>? mentionedUserIds,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      if (content.trim().isEmpty) {
        return Result.failure(const InvalidCommentContentException());
      }

      final response = await supabase
          .from('post_comments')
          .insert({
            'post_id': postId,
            'author_id': userId,
            'content': content.trim(),
          })
          .select('''
            id, post_id, author_id, content, created_at, deleted_at,
            profiles!author_id (username, avatar_url)
          ''')
          .single();

      final commentId = response['id'] as String;

      // Create mention records if any @mentions were detected
      if (mentionedUserIds != null && mentionedUserIds.isNotEmpty) {
        await _createCommentMentions(commentId, mentionedUserIds);
      }

      final profile = response['profiles'] as Map<String, dynamic>?;

      return Result.success(
        PostCommentDto.fromJson({
          'id': response['id'],
          'post_id': response['post_id'],
          'author_id': response['author_id'],
          'author_username': profile?['username'] ?? 'Unknown',
          'author_avatar_url': profile?['avatar_url'],
          'content': response['content'],
          'created_at': response['created_at'],
          'deleted_at': response['deleted_at'],
        }),
      );
    } catch (e) {
      logger.error('Failed to create comment', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to create comment: $e'),
      );
    }
  }

  /// Creates comment_mentions records via RPC.
  Future<void> _createCommentMentions(
    String commentId,
    List<String> mentionedUserIds,
  ) async {
    try {
      await supabase.rpc(
        'add_comment_mentions',
        params: {
          'p_comment_id': commentId,
          'p_mentioned_user_ids': mentionedUserIds,
        },
      );
    } catch (e) {
      // Log but don't fail the comment creation
      logger.error('Failed to create comment mentions', exception: e);
    }
  }

  @override
  FutureResult<void> deleteComment({required String commentId}) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      // Verify the user owns this comment
      final comment = await supabase
          .from('post_comments')
          .select('author_id')
          .eq('id', commentId)
          .maybeSingle();

      if (comment == null) {
        return Result.failure(const CommentNotFoundException());
      }

      if (comment['author_id'] != userId) {
        return Result.failure(const CommentUnauthorizedException());
      }

      // Soft delete
      await supabase
          .from('post_comments')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', commentId);

      return Result.success(null);
    } catch (e) {
      logger.error('Failed to delete comment', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to delete comment: $e'),
      );
    }
  }

  @override
  FutureResult<int> getCommentCount({required String postId}) async {
    try {
      final response = await supabase
          .from('post_comments')
          .select('id')
          .eq('post_id', postId)
          .isFilter('deleted_at', null)
          .count();

      return Result.success(response.count);
    } catch (e) {
      logger.error('Failed to get comment count', exception: e);
      return Result.failure(
        e is Exception ? e : Exception('Failed to get comment count: $e'),
      );
    }
  }
}
