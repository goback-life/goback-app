import 'dart:io';

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

/// Hook to create a post for manual lockout with app logo
/// 
/// Creates a post with the app icon and description "@username is going back for x hours"
Future<Result<PostModel>?> useManualLockoutPost(
  WidgetRef ref,
  Duration lockoutDuration,
) async {
  try {
    // Get current user
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

    // Get user profile for username
    final profileAsync = await ref.read(getProfileProvider(user.id).future);

    final profile = profileAsync.fold(
      (profile) => profile,
      (error) {
        logger.error('Failed to get profile', exception: error);
        return null;
      },
    );

    final username = profile?.username ?? '';
    if (username.isEmpty) {
      logger.warning('Username not found, using empty string');
    }

    // Format description: "@username is going back for x hours"
    final hours = lockoutDuration.inHours;
    final hoursText = hours == 1 ? 'hour' : 'hours';
    final description = '@$username is going back for $hours $hoursText';

    // Get app icon as File
    final logoFile = await AssetToFileHelper.copyAppIconToFile();

    // Get timezone
    final timezone = await ref.read(currentTimezoneProvider.future);

    // Create post data
    final postData = PostDataModel(
      authorId: user.id,
      contentType: ContentType.image,
      mediaFiles: [logoFile],
      contentDate: DateTime.now(),
      description: description,
      publishedTimezone: timezone,
    );

    // Create post
    final result = await ref.read(createPostProvider(postData).future);

    logger.info('Manual lockout post created successfully');
    return result;
  } catch (e, stackTrace) {
    logger.error(
      'Error creating manual lockout post',
      exception: e,
      stackTrace: stackTrace,
    );
    return Result.failure(e is Exception ? e : Exception(e.toString()));
  }
}

