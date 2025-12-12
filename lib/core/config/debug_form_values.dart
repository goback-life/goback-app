import 'package:dedecube_startup/dedecube_startup.dart';

class DebugFormValues {
  static String? getPhoneNumber() {
    return environment.tryGetString('FORM_PRECOMPILED_VALUE_PHONE_NUMBER');
  }

  static String? getVerificationCode() {
    return environment.tryGetString('FORM_PRECOMPILED_VALUE_VERIFICATION_CODE');
  }
}
