import 'package:cloudless/presentation/pages/friends_locked_out/friends_locked_out_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'friends_locked_out_routable.freezed.dart';
part 'friends_locked_out_routable.g.dart';

@freezed
sealed class FriendsLockedOutRoutable extends Routable<FriendsLockedOutRoutable>
    with _$FriendsLockedOutRoutable {
  factory FriendsLockedOutRoutable.fromJson(Map<String, dynamic> json) =>
      _$FriendsLockedOutRoutableFromJson(json);

  const FriendsLockedOutRoutable._();

  const factory FriendsLockedOutRoutable() = _FriendsLockedOutRoutable;

  @override
  String get path => '/friends-locked-out';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  FriendsLockedOutRoutable Function(Map<String, dynamic>) get fromMap =>
      FriendsLockedOutRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, FriendsLockedOutRoutable routeData) {
    return const FriendsLockedOutPage();
  }
}
