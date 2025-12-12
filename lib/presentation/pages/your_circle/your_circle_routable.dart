import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_page.dart';

part 'your_circle_routable.freezed.dart';
part 'your_circle_routable.g.dart';

@freezed
sealed class YourCircleRoutable extends Routable<YourCircleRoutable>
    with _$YourCircleRoutable {
  factory YourCircleRoutable.fromJson(Map<String, dynamic> json) =>
      _$YourCircleRoutableFromJson(json);

  const YourCircleRoutable._();

  const factory YourCircleRoutable() = _YourCircleRoutable;

  @override
  String get path => '/your_circle';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  YourCircleRoutable Function(Map<String, dynamic>) get fromMap =>
      YourCircleRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, YourCircleRoutable routeData) {
    return const YourCirclePage();
  }
}
