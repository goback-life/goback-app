import 'package:cloudless/presentation/hooks/use_launch_url.dart';
import 'package:flutter/foundation.dart';

/// Launches the privacy policy URL with error logging.
/// Delegates to [useLoggingLaunchUrl].
AsyncCallback usePrivacyPolicyLaunchUrl(String url) => useLoggingLaunchUrl(url);
