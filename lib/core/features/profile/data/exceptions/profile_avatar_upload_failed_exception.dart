import 'package:cloudless/core/features/profile/domain/exceptions/profile_exception.dart';

class ProfileAvatarUploadFailedException extends ProfileException {
  const ProfileAvatarUploadFailedException([
    super.message = 'Profile avatar upload failed.',
    String? code,
  ]) : super(code: code);
}
