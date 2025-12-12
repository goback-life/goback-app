import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';

class GetCircleMembersFailedException extends ConnectionException {
  const GetCircleMembersFailedException([
    super.message = 'Failed to retrieve circle members',
    String? code,
  ]) : super(code: code);
}
