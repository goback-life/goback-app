import 'package:dedecube_core/dedecube_core.dart';
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
