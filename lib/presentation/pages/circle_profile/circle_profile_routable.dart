import 'package:cloudless/presentation/pages/circle_profile/circle_profile_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'circle_profile_routable.freezed.dart';
part 'circle_profile_routable.g.dart';

@freezed
sealed class CircleProfileRoutable extends Routable<CircleProfileRoutable>
    with _$CircleProfileRoutable {
  factory CircleProfileRoutable.fromJson(Map<String, dynamic> json) =>
      _$CircleProfileRoutableFromJson(json);

  const CircleProfileRoutable._();

  const factory CircleProfileRoutable({@Default('') String userId}) =
      _CircleProfileRoutable;

  @override
  String get path => '/circle_profile';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  CircleProfileRoutable Function(Map<String, dynamic>) get fromMap =>
      CircleProfileRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, CircleProfileRoutable routeData) {
    return CircleProfilePage(userId: routeData.userId);
  }
}
