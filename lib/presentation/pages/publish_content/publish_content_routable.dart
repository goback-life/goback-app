import 'package:cloudless/presentation/pages/publish_content/publish_content_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'publish_content_routable.freezed.dart';
part 'publish_content_routable.g.dart';

@freezed
sealed class PublishContentRoutable extends Routable<PublishContentRoutable>
    with _$PublishContentRoutable {
  factory PublishContentRoutable.fromJson(Map<String, dynamic> json) =>
      _$PublishContentRoutableFromJson(json);

  const PublishContentRoutable._();

  const factory PublishContentRoutable() = _PublishContentRoutable;

  @override
  String get path => '/publish_content';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  PublishContentRoutable Function(Map<String, dynamic>) get fromMap =>
      PublishContentRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, PublishContentRoutable routeData) {
    return const PublishContentPage();
  }
}
