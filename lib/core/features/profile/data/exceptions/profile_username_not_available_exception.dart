import 'package:cloudless/core/features/profile/domain/exceptions/profile_exception.dart';

class ProfileUsernameNotAvailableException extends ProfileException {
  ProfileUsernameNotAvailableException(this.username, [String? code])
    : super('$username is not available', code: code);

  final String username;

  @override
  String toString() =>
      'ProfileUsernameNotAvailableException(message: $message)';
}
