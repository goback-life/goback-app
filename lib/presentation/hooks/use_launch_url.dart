import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LaunchUrlFunction = Future<bool> Function();

LaunchUrlFunction useLaunchUrl(
  String url, {
  LaunchMode mode = LaunchMode.externalApplication,
}) {
  return useMemoized(() {
    return () async {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: mode);
      }

      return false;
    };
  }, [url, mode]);
}

/// Generic hook that wraps [useLaunchUrl] with error logging.
/// Used by specialized launch URL hooks (privacy policy, terms of service, etc.)
AsyncCallback useLoggingLaunchUrl(String url) {
  final launch = useLaunchUrl(url);

  return useCallback(() async {
    final result = await launch();
    if (!result) {
      logger.error('Failed to launch URL: $url');
    }
  }, [launch]);
}
