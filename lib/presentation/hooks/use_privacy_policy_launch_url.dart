import 'package:cloudless/presentation/hooks/use_launch_url.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/foundation.dart';

AsyncCallback usePrivacyPolicyLaunchUrl(String url) {
  final launchUrl = useLaunchUrl(url);

  return useCallback(() async {
    final result = await launchUrl();
    if (!result) {
      logger.error('Failed to launch URL: $url');
    }
  }, [launchUrl]);
}
