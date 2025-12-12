import 'package:cloudless/presentation/pages/time_limit_reached/time_limit_reached_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'time_limit_reached_routable.freezed.dart';
part 'time_limit_reached_routable.g.dart';

@freezed
sealed class TimeLimitReachedRoutable extends Routable<TimeLimitReachedRoutable>
    with _$TimeLimitReachedRoutable {
  factory TimeLimitReachedRoutable.fromJson(Map<String, dynamic> json) =>
      _$TimeLimitReachedRoutableFromJson(json);

  const TimeLimitReachedRoutable._();

  const factory TimeLimitReachedRoutable() = _TimeLimitReachedRoutable;

  @override
  String get path => '/time_limit_reached';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  TimeLimitReachedRoutable Function(Map<String, dynamic>) get fromMap =>
      TimeLimitReachedRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, TimeLimitReachedRoutable routeData) {
    return const TimeLimitReachedPage();
  }
}
