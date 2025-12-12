import 'package:flutter/material.dart';

class MainElevatedButton extends StatelessWidget {
  const MainElevatedButton({
    required this.title,
    required this.onPressed,
    this.backgroundColor,
    super.key,
  });

  final String title;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? nonNullOnPressed = onPressed != null
        ? () {
            FocusManager.instance.primaryFocus?.unfocus();
            onPressed!.call();
          }
        : null;
    final ButtonStyle? style = backgroundColor != null
        ? ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
          )
        : null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: style,
        onPressed: nonNullOnPressed,
        child: Text(title),
      ),
    );
  }
}
