import 'package:cloudless/presentation/pages/objective/objective_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'objective_routable.freezed.dart';
part 'objective_routable.g.dart';

@freezed
sealed class ObjectiveRoutable extends Routable<ObjectiveRoutable> with _$ObjectiveRoutable {
  factory ObjectiveRoutable.fromJson(Map<String, dynamic> json) =>
      _$ObjectiveRoutableFromJson(json);

  const ObjectiveRoutable._();

  const factory ObjectiveRoutable({
    @Default(false) bool showBackButton,
    @Default(true) bool showBottomButton,
  }) = _ObjectiveRoutable;

  @override
  String get path => '/objective';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  ObjectiveRoutable Function(Map<String, dynamic>) get fromMap =>
      ObjectiveRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, ObjectiveRoutable routeData) {
    return ObjectivePage(
      showBackButton: routeData.showBackButton,
      showBottomButton: routeData.showBottomButton,
    );
  }
}