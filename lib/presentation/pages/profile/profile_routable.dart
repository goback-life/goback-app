import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:cloudless/presentation/pages/profile/profile_page.dart';

part 'profile_routable.freezed.dart';
part 'profile_routable.g.dart';

@freezed
sealed class ProfileRoutable extends Routable<ProfileRoutable>
    with _$ProfileRoutable {
  factory ProfileRoutable.fromJson(Map<String, dynamic> json) =>
      _$ProfileRoutableFromJson(json);

  const ProfileRoutable._();

  const factory ProfileRoutable() = _ProfileRoutable;

  @override
  String get path => '/profile';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  ProfileRoutable Function(Map<String, dynamic>) get fromMap =>
      ProfileRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, ProfileRoutable routeData) {
    return const ProfilePage();
  }
}
