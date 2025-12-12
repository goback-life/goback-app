import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_page.dart';

part 'sign_in_routable.freezed.dart';
part 'sign_in_routable.g.dart';

@freezed
sealed class SignInRoutable extends Routable<SignInRoutable>
    with _$SignInRoutable {
  factory SignInRoutable.fromJson(Map<String, dynamic> json) =>
      _$SignInRoutableFromJson(json);

  const SignInRoutable._();

  const factory SignInRoutable() = _SignInRoutable;

  @override
  String get path => '/sign_in';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  SignInRoutable Function(Map<String, dynamic>) get fromMap =>
      SignInRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, SignInRoutable routeData) {
    return const SignInPage();
  }
}
