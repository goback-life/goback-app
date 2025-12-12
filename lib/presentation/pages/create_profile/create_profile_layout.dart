import 'package:cloudless/presentation/utilities/main_layout.dart';

mixin CreateProfileLayout on MainLayout {
  @override
  double get horizontalPadding => 16.0;

  @override
  double get bottomMargin => 10.0;

  @override
  double get topMargin => 70.0;

  double get titleToImage => 24.0;

  double get editTextToUsernameField => 24.0;

  double get usernameFieldToBioField => 32.0;

  double get imageToEdit => 12.0;
}
