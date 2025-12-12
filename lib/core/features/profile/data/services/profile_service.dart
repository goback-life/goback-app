import 'dart:io';

import 'package:cloudless/core/features/profile/data/dtos/avatar_upload_response_dto.dart';
import 'package:cloudless/core/features/profile/data/dtos/create_or_update_profile_request_dto.dart';
import 'package:cloudless/core/features/profile/data/dtos/create_or_update_profile_response_dto.dart';
import 'package:cloudless/core/features/profile/data/dtos/get_profile_response_dto.dart';
import 'package:cloudless/core/features/profile/data/exceptions/profile_avatar_upload_failed_exception.dart';
import 'package:cloudless/core/features/profile/domain/contracts/profile_service_contract.dart';
import 'package:cloudless/core/features/storage/data/providers/signed_url_provider.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_buckets.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_tables.dart';
import 'package:cloudless/core/utilities/file_image_type_extensions.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService implements ProfileServiceContract {
  const ProfileService({required this.supabaseClient, required this.ref});

  final SupabaseClient supabaseClient;
  final Ref ref;

  @override
  FutureResult<CreateOrUpdateProfileResponseDto> createOrUpdateProfile(
    CreateOrUpdateProfileRequestDto profileDto,
  ) async {
    try {
      final response = await supabaseClient
          .from(SupabaseTables.profiles)
          .upsert(profileDto)
          .select()
          .single();

      return Result.success(
        CreateOrUpdateProfileResponseDto.fromJson(response),
      );
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<GetProfileResponseDto?> getProfile(String userId) async {
    try {
      final response = await supabaseClient
          .from(SupabaseTables.profiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return Result.success(null);
      }

      String? avatarUrl;
      try {
        avatarUrl = await ref.read(
          signedUrlProvider(SupabaseBuckets.avatars, userId).future,
        );
      } on StorageException catch (_) {
        avatarUrl = null;
      }

      final dto = GetProfileResponseDto.fromJson({
        ...response,
        'id': userId,
        'avatar_url': avatarUrl,
      });

      return Result.success(dto);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<bool> checkUsernameAvailability(String username) async {
    try {
      final response = await supabaseClient
          .from(SupabaseTables.profiles)
          .select('id')
          .ilike('username', username)
          .limit(1);

      return Result.success(response.isEmpty);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<AvatarUploadResponseDto> uploadAvatar(
    String userId,
    File imageFile,
  ) async {
    try {
      final fileName = userId;
      final contentType = await imageFile.detectImageContentType();

      await supabaseClient.storage
          .from(SupabaseBuckets.avatars)
          .upload(
            fileName,
            imageFile,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      // Invalidate the provider cache since we uploaded a new avatar
      ref.invalidate(signedUrlProvider(SupabaseBuckets.avatars, fileName));

      final signedUrl = await ref.read(
        signedUrlProvider(SupabaseBuckets.avatars, fileName).future,
      );

      if (signedUrl == null) {
        return Result.failure(
          const ProfileAvatarUploadFailedException(
            'Failed to create signed URL for the uploaded avatar.',
          ),
        );
      }

      return Result.success(AvatarUploadResponseDto(publicUrl: signedUrl));
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }

  @override
  FutureResult<bool> hasCompletedProfile(String userId) async {
    try {
      final response = await supabaseClient
          .from(SupabaseTables.profiles)
          .select('username')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        return Result.success(false);
      }

      final username = response['username'] as String?;
      if (username == null) {
        return Result.success(false);
      }

      final completed = username.trim().isNotEmpty;

      return Result.success(completed);
    } on Exception catch (e) {
      return Result.failure(e);
    }
  }
}
