import 'package:cloudless/core/exceptions/main_exception.dart';

/// Thrown when there are network connectivity issues.
///
/// **When it occurs:**
/// - Network connection is lost during operation
/// - Server is unreachable due to network issues
/// - DNS resolution fails
/// - Connection timeout due to poor network
///
/// **Common scenarios:**
/// - Mobile device switches networks
/// - Wi-Fi connection drops
/// - Server maintenance or downtime
/// - Firewall blocking connections
class NetworkConnectionException extends MainException {
  const NetworkConnectionException([String? message, String? code])
    : super(message ?? 'Network connection failed', code: code);
}
