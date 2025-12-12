import 'dart:io';

import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

abstract class ProfileRepositoryContract {
  /// Creates a new profile or updates an existing one with the provided
  /// primitive parameters.
  ///
  /// Returns a [FutureResult] containing the updated [ProfileModel].
  /// Throws an error if the operation fails.
  FutureResult<ProfileModel> createOrUpdateProfile({
    required String id,
    required String username,
    String? biography,
  });

  /// Retrieves the profile information for the user with the given [userId].
  ///
  /// Returns a [FutureResult] containing the [ProfileModel], or `null` if not found.
  /// Throws an error if the operation fails.
  FutureResult<ProfileModel?> getProfile(String userId);

  /// Checks if the specified [username] is available for registration.
  ///
  /// Returns a [FutureResult] containing `true` if the username is available, `false` otherwise.
  /// Throws an error if the operation fails.
  FutureResult<bool> checkUsernameAvailability(String username);

  /// Uploads an avatar image for the user with the given [userId].
  ///
  /// The [imageFile] parameter should be a [File] containing the image to upload.
  /// Returns a [FutureResult] containing the URL of the uploaded avatar image.
  /// Throws an error if the operation fails.
  FutureResult<String> uploadAvatar(String userId, File imageFile);

  /// Returns whether the user with [userId] has a completed profile according to
  /// app rules.
  FutureResult<bool> hasCompletedProfile(String userId);
}
