/// A contract for HTTP logger configuration.
///
/// Defines the configuration options for HTTP request/response logging.
/// This contract specifies which parts of HTTP transactions should be logged.
abstract class HttpLoggerConfigContract {
  /// Whether logging is enabled.
  bool get isEnabled;

  //
  // ── Request ──
  //

  /// Whether to log request body data.
  bool get logRequestData;

  /// Whether to log request headers.
  bool get logRequestHeaders;

  //
  // ── Response ──
  //

  /// Whether to log response body data.
  bool get logResponseData;

  /// Whether to log response headers.
  bool get logResponseHeaders;

  /// Whether to log response status messages.
  bool get logResponseMessage;

  /// Whether to log response redirects.
  bool get logResponseRedirects;

  /// Whether to log response time metrics.
  bool get logResponseTime;

  //
  // ── Error ──
  //

  /// Whether to log error response body data.
  bool get logErrorData;

  /// Whether to log headers on error responses.
  bool get logErrorHeaders;

  /// Whether to log error messages.
  bool get logErrorMessage;
}
