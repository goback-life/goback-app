import 'package:cloudless/presentation/pages/otp/otp_page.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

part 'otp_routable.freezed.dart';
part 'otp_routable.g.dart';

@freezed
sealed class OtpRoutable extends Routable<OtpRoutable> with _$OtpRoutable {
  factory OtpRoutable.fromJson(Map<String, dynamic> json) =>
      _$OtpRoutableFromJson(json);

  const OtpRoutable._();

  const factory OtpRoutable({@Default('') String phoneNumber}) = _OtpRoutable;

  @override
  String get path => '/otp';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  OtpRoutable Function(Map<String, dynamic>) get fromMap =>
      OtpRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, OtpRoutable routeData) {
    return OtpPage(phoneNumber: routeData.phoneNumber);
  }
}
