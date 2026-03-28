import 'package:cloudless/presentation/hooks/use_launch_url.dart';
import 'package:flutter/foundation.dart';

/// Launches the terms of service URL with error logging.
/// Delegates to [useLoggingLaunchUrl].
AsyncCallback useTermsOfServiceLaunchUrl(String url) => useLoggingLaunchUrl(url);
