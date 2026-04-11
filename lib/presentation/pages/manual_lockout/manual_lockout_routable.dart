import 'package:cloudless/presentation/pages/manual_lockout/manual_lockout_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'manual_lockout_routable.freezed.dart';
part 'manual_lockout_routable.g.dart';

@freezed
sealed class ManualLockoutRoutable extends Routable<ManualLockoutRoutable>
    with _$ManualLockoutRoutable {
  factory ManualLockoutRoutable.fromJson(Map<String, dynamic> json) =>
      _$ManualLockoutRoutableFromJson(json);

  const ManualLockoutRoutable._();

  const factory ManualLockoutRoutable() = _ManualLockoutRoutable;

  @override
  String get path => '/manual_lockout';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  ManualLockoutRoutable Function(Map<String, dynamic>) get fromMap =>
      ManualLockoutRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, ManualLockoutRoutable routeData) {
    return const ManualLockoutPage();
  }
}
