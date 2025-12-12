import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:cloudless/presentation/pages/join_circle/join_circle_page.dart';

part 'join_circle_routable.freezed.dart';
part 'join_circle_routable.g.dart';

@freezed
sealed class JoinCircleRoutable extends Routable<JoinCircleRoutable>
    with _$JoinCircleRoutable {
  factory JoinCircleRoutable.fromJson(Map<String, dynamic> json) =>
      _$JoinCircleRoutableFromJson(json);

  const JoinCircleRoutable._();

  const factory JoinCircleRoutable() = _JoinCircleRoutable;

  @override
  String get path => '/join_circle';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  JoinCircleRoutable Function(Map<String, dynamic>) get fromMap =>
      JoinCircleRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, JoinCircleRoutable routeData) {
    return const JoinCirclePage();
  }
}
