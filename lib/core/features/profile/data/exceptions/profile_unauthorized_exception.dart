import 'package:cloudless/core/features/profile/domain/exceptions/profile_exception.dart';

class ProfileUnauthorizedException extends ProfileException {
  const ProfileUnauthorizedException([String? code])
    : super('Profile access unauthorized', code: code);
}
