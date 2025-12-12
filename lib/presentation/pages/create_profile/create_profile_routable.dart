import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:cloudless/presentation/pages/create_profile/create_profile_page.dart';

part 'create_profile_routable.freezed.dart';
part 'create_profile_routable.g.dart';

@freezed
sealed class CreateProfileRoutable extends Routable<CreateProfileRoutable>
    with _$CreateProfileRoutable {
  factory CreateProfileRoutable.fromJson(Map<String, dynamic> json) =>
      _$CreateProfileRoutableFromJson(json);

  const CreateProfileRoutable._();

  const factory CreateProfileRoutable() = _CreateProfileRoutable;

  @override
  String get path => '/create_profile';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  CreateProfileRoutable Function(Map<String, dynamic>) get fromMap =>
      CreateProfileRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, CreateProfileRoutable routeData) {
    return const CreateProfilePage();
  }
}
