import 'package:cloudless/presentation/hooks/use_launch_url.dart';
import 'package:flutter/foundation.dart';

/// Launches the assistance URL with error logging.
/// Delegates to [useLoggingLaunchUrl].
AsyncCallback useAssistanceLaunchUrl(String url) => useLoggingLaunchUrl(url);
