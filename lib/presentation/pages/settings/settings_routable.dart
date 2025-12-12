import 'package:cloudless/presentation/pages/settings/settings_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'settings_routable.freezed.dart';
part 'settings_routable.g.dart';

@freezed
sealed class SettingsRoutable extends Routable<SettingsRoutable>
    with _$SettingsRoutable {
  factory SettingsRoutable.fromJson(Map<String, dynamic> json) =>
      _$SettingsRoutableFromJson(json);

  const SettingsRoutable._();

  const factory SettingsRoutable() = _SettingsRoutable;

  @override
  String get path => '/settings';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  SettingsRoutable Function(Map<String, dynamic>) get fromMap =>
      SettingsRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, SettingsRoutable routeData) {
    return const SettingsPage();
  }
}
