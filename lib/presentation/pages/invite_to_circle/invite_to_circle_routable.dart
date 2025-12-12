import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/invite_to_circle_page.dart';

part 'invite_to_circle_routable.freezed.dart';
part 'invite_to_circle_routable.g.dart';

@freezed
sealed class InviteToCircleRoutable extends Routable<InviteToCircleRoutable>
    with _$InviteToCircleRoutable {
  factory InviteToCircleRoutable.fromJson(Map<String, dynamic> json) =>
      _$InviteToCircleRoutableFromJson(json);

  const InviteToCircleRoutable._();

  const factory InviteToCircleRoutable() = _InviteToCircleRoutable;

  @override
  String get path => '/invite_to_circle';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  InviteToCircleRoutable Function(Map<String, dynamic>) get fromMap =>
      InviteToCircleRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, InviteToCircleRoutable routeData) {
    return const InviteToCirclePage();
  }
}
