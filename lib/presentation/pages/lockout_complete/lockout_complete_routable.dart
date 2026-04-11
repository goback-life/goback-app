import 'package:cloudless/presentation/pages/lockout_complete/lockout_complete_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'lockout_complete_routable.freezed.dart';
part 'lockout_complete_routable.g.dart';

@freezed
sealed class LockoutCompleteRoutable extends Routable<LockoutCompleteRoutable>
    with _$LockoutCompleteRoutable {
  factory LockoutCompleteRoutable.fromJson(Map<String, dynamic> json) =>
      _$LockoutCompleteRoutableFromJson(json);

  const LockoutCompleteRoutable._();

  const factory LockoutCompleteRoutable({required String lockoutSessionId}) =
      _LockoutCompleteRoutable;

  @override
  String get path => '/lockout_complete';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  LockoutCompleteRoutable Function(Map<String, dynamic>) get fromMap =>
      LockoutCompleteRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, LockoutCompleteRoutable routeData) {
    return LockoutCompletePage(lockoutSessionId: routeData.lockoutSessionId);
  }
}
