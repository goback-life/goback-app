import 'package:talker_flutter/talker_flutter.dart';

class RouteLog extends TalkerLog {
  RouteLog({
    required String message,
  }) : super(message);

  @override
  AnsiPen get pen => AnsiPen()..xterm(135);

  @override
  String get key => TalkerLogType.route.key;
}
