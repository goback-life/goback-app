import 'package:cloudless/core/features/post/data/dtos/post_reaction_dto.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for managing post reactions.
class PostReactionService {
  const PostReactionService({required this.supabaseClient});

  final SupabaseClient supabaseClient;

  /// Gets all reactions for a specific post.
  Future<List<PostReactionDto>> getPostReactions({
    required String postId,
  }) async {
    try {
      final response = await supabaseClient
          .from('post_reactions')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => PostReactionDto.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      logger.error(
        'Failed to get post reactions',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds or updates a reaction to a post.
  Future<PostReactionDto> addReaction({
    required String postId,
    required String userId,
    required String reaction,
  }) async {
    try {
      final existingReaction = await supabaseClient
          .from('post_reactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingReaction != null) {
        final response = await supabaseClient
            .from('post_reactions')
            .update({
              'reaction': reaction,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('post_id', postId)
            .eq('user_id', userId)
            .select()
            .single();

        logger.info('Reaction updated for post $postId by user $userId');
        return PostReactionDto.fromJson(response);
      } else {
        final response = await supabaseClient
            .from('post_reactions')
            .insert({
              'post_id': postId,
              'user_id': userId,
              'reaction': reaction,
            })
            .select()
            .single();

        logger.info('Reaction added to post $postId by user $userId');
        return PostReactionDto.fromJson(response);
      }
    } catch (e, stackTrace) {
      logger.error(
        'Failed to add reaction',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Deletes a reaction by its ID.
  Future<void> deleteReaction({required String reactionId}) async {
    try {
      await supabaseClient.from('post_reactions').delete().eq('id', reactionId);

      logger.info('Reaction $reactionId deleted');
    } catch (e, stackTrace) {
      logger.error(
        'Failed to delete reaction',
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
