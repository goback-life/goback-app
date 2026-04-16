import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:cloudless/presentation/pages/circle_hub/circle_hub_page.dart';

part 'circle_hub_routable.freezed.dart';
part 'circle_hub_routable.g.dart';

@freezed
sealed class CircleHubRoutable extends Routable<CircleHubRoutable>
    with _$CircleHubRoutable {
  factory CircleHubRoutable.fromJson(Map<String, dynamic> json) =>
      _$CircleHubRoutableFromJson(json);

  const CircleHubRoutable._();

  const factory CircleHubRoutable() = _CircleHubRoutable;

  @override
  String get path => '/circle_hub';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  CircleHubRoutable Function(Map<String, dynamic>) get fromMap =>
      CircleHubRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, CircleHubRoutable routeData) {
    return const CircleHubPage();
  }
}
