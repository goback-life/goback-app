import 'dart:io';

import 'package:cloudless/core/features/profile/data/dtos/avatar_upload_response_dto.dart';
import 'package:cloudless/core/features/profile/data/dtos/create_or_update_profile_request_dto.dart';
import 'package:cloudless/core/features/profile/data/dtos/create_or_update_profile_response_dto.dart';
import 'package:cloudless/core/features/profile/data/dtos/get_profile_response_dto.dart';
import 'package:dedecube_core/dedecube_core.dart';

abstract class ProfileServiceContract {
  /// Creates a new profile or updates an existing one with the provided [profileDto].
  ///
  /// Returns a [FutureResult] containing the updated profile data as a [CreateOrUpdateProfileResponseDto].
  /// Throws an error if the operation fails.
  FutureResult<CreateOrUpdateProfileResponseDto> createOrUpdateProfile(
    CreateOrUpdateProfileRequestDto profileDto,
  );

  /// Retrieves the profile information for the user with the given [userId].
  ///
  /// Returns a [FutureResult] containing the profile data as a [GetProfileResponseDto], or `null` if not found.
  /// Throws an error if the operation fails.
  FutureResult<GetProfileResponseDto?> getProfile(String userId);

  /// Checks if the specified [username] is available for registration.
  ///
  /// Returns a [FutureResult] containing `true` if the username is available, `false` otherwise.
  /// Throws an error if the operation fails.
  FutureResult<bool> checkUsernameAvailability(String username);

  /// Uploads an avatar image for the user with the given [userId].
  ///
  /// The [imageFile] parameter should be a [File] containing the image to upload.
  /// Returns a [FutureResult] containing the avatar upload response with the URL.
  /// Throws an error if the operation fails.
  FutureResult<AvatarUploadResponseDto> uploadAvatar(
    String userId,
    File imageFile,
  );

  /// Returns whether the user with [userId] has a completed profile.
  FutureResult<bool> hasCompletedProfile(String userId);
}
