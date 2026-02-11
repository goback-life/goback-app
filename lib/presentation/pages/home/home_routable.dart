import 'package:cloudless/presentation/pages/feed/feed_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'home_routable.freezed.dart';
part 'home_routable.g.dart';

@freezed
sealed class HomeRoutable extends Routable<HomeRoutable>
    with _$HomeRoutable {
  factory HomeRoutable.fromJson(Map<String, dynamic> json) =>
      _$HomeRoutableFromJson(json);

  const HomeRoutable._();

  const factory HomeRoutable() = _HomeRoutable;

  @override
  String get path => '/home';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  HomeRoutable Function(Map<String, dynamic>) get fromMap =>
      HomeRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, HomeRoutable routeData) {
    return const FeedPage();
  }
}
