import 'package:cloudless/presentation/pages/external_profile/external_profile_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'external_profile_routable.freezed.dart';
part 'external_profile_routable.g.dart';

@freezed
sealed class ExternalProfileRoutable extends Routable<ExternalProfileRoutable>
    with _$ExternalProfileRoutable {
  factory ExternalProfileRoutable.fromJson(Map<String, dynamic> json) =>
      _$ExternalProfileRoutableFromJson(json);

  const ExternalProfileRoutable._();

  const factory ExternalProfileRoutable({@Default('') String userId}) =
      _ExternalProfileRoutable;

  @override
  String get path => '/external_profile';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  ExternalProfileRoutable Function(Map<String, dynamic>) get fromMap =>
      ExternalProfileRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, ExternalProfileRoutable routeData) {
    return ExternalProfilePage(userId: routeData.userId);
  }
}
