import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:cloudless/core/features/post/domain/models/post_data_model.dart';
import 'package:cloudless/core/features/post/domain/models/post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/create_post_provider.dart';
import 'package:cloudless/core/features/profile/domain/providers/get_profile_provider.dart';
import 'package:cloudless/core/utilities/asset_to_file_helper.dart';
import 'package:cloudless/core/features/timezone/data/providers/current_timezone_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

/// Hook to create a post when joining someone else's lockout with app logo
/// 
/// Creates a post with the app icon and description "@joiner is going back for x hours with @other_user"
/// Tags the other user (the lockout creator)
Future<Result<PostModel>?> useJoinLockoutPost(
  WidgetRef ref,
  Duration lockoutDuration,
  String otherUserId,
  String otherUserUsername,
) async {
  try {
    // Get current user (the joiner)
    final currentUserAsync = await ref.read(getCurrentUserProvider.future);
    
    final user = currentUserAsync.fold(
      (user) => user,
      (error) {
        logger.error('Failed to get current user', exception: error);
        return null;
      },
    );

    if (user == null) {
      return Result.failure(Exception('User not found'));
    }

    // Get joiner's profile for username
    final profileAsync = await ref.read(getProfileProvider(user.id).future);

    final profile = profileAsync.fold(
      (profile) => profile,
      (error) {
        logger.error('Failed to get profile', exception: error);
        return null;
      },
    );

    final joinerUsername = profile?.username ?? '';
    if (joinerUsername.isEmpty) {
      logger.warning('Username not found, using empty string');
    }

    // Format description: "@joiner is going back for x hours with @other_user"
    final totalMinutes = lockoutDuration.inMinutes;
    final hours = lockoutDuration.inHours;
    
    String description;
    if (totalMinutes < 60) {
      // Less than 1 hour, use minutes
      final minutesText = totalMinutes == 1 ? 'minute' : 'minutes';
      description = '@$joinerUsername is going back for $totalMinutes $minutesText with @$otherUserUsername';
    } else {
      // 1 hour or more, use hours
      final hoursText = hours == 1 ? 'hour' : 'hours';
      description = '@$joinerUsername is going back for $hours $hoursText with @$otherUserUsername';
    }

    // Get app icon as File
    final logoFile = await AssetToFileHelper.copyAppIconToFile();

    // Get timezone
    final timezone = await ref.read(currentTimezoneProvider.future);

    // Create post data with tag to the other user (lockout creator)
    final postData = PostDataModel(
      authorId: user.id, // Post on joiner's account
      contentType: ContentType.image,
      mediaFiles: [logoFile],
      description: description,
      taggedUserIds: [otherUserId], // Tag the other user (lockout creator)
      publishedTimezone: timezone,
    );

    // Create post
    final result = await ref.read(createPostProvider(postData).future);

    logger.info('Join lockout post created successfully');
    return result;
  } catch (e, stackTrace) {
    logger.error(
      'Error creating join lockout post',
      exception: e,
      stackTrace: stackTrace,
    );
    return Result.failure(e is Exception ? e : Exception(e.toString()));
  }
}
