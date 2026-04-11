import 'package:cloudless/presentation/pages/notifications/notifications_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'notifications_routable.freezed.dart';
part 'notifications_routable.g.dart';

@freezed
sealed class NotificationsRoutable extends Routable<NotificationsRoutable>
    with _$NotificationsRoutable {
  factory NotificationsRoutable.fromJson(Map<String, dynamic> json) =>
      _$NotificationsRoutableFromJson(json);

  const NotificationsRoutable._();

  const factory NotificationsRoutable() = _NotificationsRoutable;

  @override
  String get path => '/notifications';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  NotificationsRoutable Function(Map<String, dynamic>) get fromMap =>
      NotificationsRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, NotificationsRoutable routeData) {
    return const NotificationsPage();
  }
}
