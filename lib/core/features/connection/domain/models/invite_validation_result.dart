// ignore_for_file: one_class_per_file
sealed class InviteValidationResult {
  const InviteValidationResult();

  factory InviteValidationResult.valid({
    required Map<String, dynamic> creatorProfile,
  }) = ValidInviteResult;

  factory InviteValidationResult.invalid(String errorMessage) =
      InvalidInviteResult;

  bool get isValid => this is ValidInviteResult;
  bool get isInvalid => this is InvalidInviteResult;

  T when<T>({
    required T Function(Map<String, dynamic> creatorProfile) valid,
    required T Function(String errorMessage) invalid,
  }) {
    return switch (this) {
      ValidInviteResult(creatorProfile: final profile) => valid(profile),
      InvalidInviteResult(errorMessage: final message) => invalid(message),
    };
  }
}

class ValidInviteResult extends InviteValidationResult {
  const ValidInviteResult({required this.creatorProfile});

  final Map<String, dynamic> creatorProfile;
}

class InvalidInviteResult extends InviteValidationResult {
  const InvalidInviteResult(this.errorMessage);

  final String errorMessage;
}
