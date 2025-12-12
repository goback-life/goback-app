import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:cloudless/presentation/pages/edit_profile/edit_profile_page.dart';

part 'edit_profile_routable.freezed.dart';
part 'edit_profile_routable.g.dart';

@freezed
sealed class EditProfileRoutable extends Routable<EditProfileRoutable>
    with _$EditProfileRoutable {
  factory EditProfileRoutable.fromJson(Map<String, dynamic> json) =>
      _$EditProfileRoutableFromJson(json);

  const EditProfileRoutable._();

  const factory EditProfileRoutable() = _EditProfileRoutable;

  @override
  String get path => '/edit_profile';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  EditProfileRoutable Function(Map<String, dynamic>) get fromMap =>
      EditProfileRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, EditProfileRoutable routeData) {
    return const EditProfilePage();
  }
}
