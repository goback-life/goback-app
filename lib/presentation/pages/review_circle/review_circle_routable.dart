import 'package:cloudless/presentation/pages/review_circle/review_circle_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'review_circle_routable.freezed.dart';
part 'review_circle_routable.g.dart';

@freezed
sealed class ReviewCircleRoutable extends Routable<ReviewCircleRoutable>
    with _$ReviewCircleRoutable {
  factory ReviewCircleRoutable.fromJson(Map<String, dynamic> json) =>
      _$ReviewCircleRoutableFromJson(json);

  const ReviewCircleRoutable._();

  const factory ReviewCircleRoutable() = _ReviewCircleRoutable;

  @override
  String get path => '/review_circle';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  ReviewCircleRoutable Function(Map<String, dynamic>) get fromMap =>
      ReviewCircleRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, ReviewCircleRoutable routeData) {
    return const ReviewCirclePage();
  }
}

