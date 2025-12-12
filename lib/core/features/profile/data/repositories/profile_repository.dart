import 'dart:io';

import 'package:cloudless/core/features/profile/data/dtos/avatar_upload_response_dto.dart';
import 'package:cloudless/core/features/profile/data/dtos/create_or_update_profile_request_dto.dart';
import 'package:cloudless/core/features/profile/data/dtos/create_or_update_profile_response_dto.dart';
import 'package:cloudless/core/features/profile/data/dtos/get_profile_response_dto.dart';
import 'package:cloudless/core/features/profile/data/mappers/check_username_availability_exceptions_mapper.dart';
import 'package:cloudless/core/features/profile/data/mappers/create_or_update_profile_exceptions_mapper.dart';
import 'package:cloudless/core/features/profile/data/mappers/create_or_update_profile_response_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/profile/data/mappers/get_profile_exceptions_mapper.dart';
import 'package:cloudless/core/features/profile/data/mappers/get_profile_response_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/profile/data/mappers/has_completed_profile_exceptions_mapper.dart';
import 'package:cloudless/core/features/profile/data/mappers/upload_avatar_exceptions_mapper.dart';
import 'package:cloudless/core/features/profile/domain/contracts/profile_repository_contract.dart';
import 'package:cloudless/core/features/profile/domain/contracts/profile_service_contract.dart';
import 'package:cloudless/core/features/supabase/data/mixins/supabase_result_processor.dart';
import 'package:cloudless/core/models/profile_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

class ProfileRepository
    with SupabaseResultProcessor
    implements ProfileRepositoryContract {
  const ProfileRepository({required this.profileService});

  final ProfileServiceContract profileService;

  @override
  FutureResult<ProfileModel> createOrUpdateProfile({
    required String id,
    required String username,
    String? biography,
    String? avatarUrl,
  }) async {
    return processSupabaseResult<
      CreateOrUpdateProfileResponseDto,
      ProfileModel
    >(
      request: () => profileService.createOrUpdateProfile(
        CreateOrUpdateProfileRequestDto(
          id: id,
          username: username,
          biography: biography,
        ),
      ),
      responseMapper: (dto) async {
        return CreateOrUpdateProfileResponseDtoToModelMapper().mapDto(dto);
      },
      exceptionMapper:
          CreateOrUpdateProfileExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<ProfileModel?> getProfile(String userId) async {
    return processSupabaseResult<GetProfileResponseDto?, ProfileModel?>(
      request: () => profileService.getProfile(userId),
      responseMapper: (dto) async {
        if (dto == null) {
          return null;
        }

        return GetProfileResponseDtoToModelMapper().mapDto(dto);
      },
      exceptionMapper: GetProfileExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<bool> checkUsernameAvailability(String username) async {
    return processSupabaseResult<bool, bool>(
      request: () => profileService.checkUsernameAvailability(username),
      responseMapper: (dto) async => dto,
      exceptionMapper:
          CheckUsernameAvailabilityExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<String> uploadAvatar(String userId, File imageFile) async {
    return processSupabaseResult<AvatarUploadResponseDto, String>(
      request: () => profileService.uploadAvatar(userId, imageFile),
      responseMapper: (dto) async => dto.publicUrl,
      exceptionMapper: UploadAvatarExceptionsMapper.fromSupabaseException,
    );
  }

  @override
  FutureResult<bool> hasCompletedProfile(String userId) async {
    return processSupabaseResult<bool, bool>(
      request: () => profileService.hasCompletedProfile(userId),
      responseMapper: (dto) async => dto,
      exceptionMapper:
          HasCompletedProfileExceptionsMapper.fromSupabaseException,
    );
  }
}
