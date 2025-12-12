import 'package:cloudless/presentation/pages/content_editor/content_editor_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'content_editor_routable.freezed.dart';
part 'content_editor_routable.g.dart';

@freezed
sealed class ContentEditorRoutable extends Routable<ContentEditorRoutable>
    with _$ContentEditorRoutable {
  factory ContentEditorRoutable.fromJson(Map<String, dynamic> json) =>
      _$ContentEditorRoutableFromJson(json);

  const ContentEditorRoutable._();

  const factory ContentEditorRoutable() = _ContentEditorRoutable;

  @override
  String get path => '/content_editor';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  ContentEditorRoutable Function(Map<String, dynamic>) get fromMap =>
      ContentEditorRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, ContentEditorRoutable routeData) {
    return const ContentEditorPage();
  }
}
