import 'package:cloudless/presentation/pages/tutorial/tutorial_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'tutorial_routable.freezed.dart';
part 'tutorial_routable.g.dart';

@freezed
sealed class TutorialRoutable extends Routable<TutorialRoutable>
    with _$TutorialRoutable {
  factory TutorialRoutable.fromJson(Map<String, dynamic> json) =>
      _$TutorialRoutableFromJson(json);

  const TutorialRoutable._();

  const factory TutorialRoutable() = _TutorialRoutable;

  @override
  String get path => '/tutorial';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  TutorialRoutable Function(Map<String, dynamic>) get fromMap =>
      TutorialRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, TutorialRoutable routeData) {
    return const TutorialPage();
  }
}
