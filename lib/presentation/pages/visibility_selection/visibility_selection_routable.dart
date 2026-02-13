import 'package:cloudless/presentation/pages/visibility_selection/visibility_selection_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'visibility_selection_routable.freezed.dart';
part 'visibility_selection_routable.g.dart';

@freezed
sealed class VisibilitySelectionRoutable
    extends Routable<VisibilitySelectionRoutable>
    with _$VisibilitySelectionRoutable {
  factory VisibilitySelectionRoutable.fromJson(Map<String, dynamic> json) =>
      _$VisibilitySelectionRoutableFromJson(json);

  const VisibilitySelectionRoutable._();

  const factory VisibilitySelectionRoutable() = _VisibilitySelectionRoutable;

  @override
  String get path => '/visibility_selection';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  VisibilitySelectionRoutable Function(Map<String, dynamic>) get fromMap =>
      VisibilitySelectionRoutable.fromJson;

  @override
  Widget buildPage(
    BuildContext context,
    VisibilitySelectionRoutable routeData,
  ) {
    return const VisibilitySelectionPage();
  }
}
