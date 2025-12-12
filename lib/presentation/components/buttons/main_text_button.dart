import 'package:flutter/material.dart';

class MainTextButton extends StatelessWidget {
  const MainTextButton({
    required this.title,
    required this.onPressed,
    super.key,
  });

  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? nonNullOnPressed = onPressed != null
        ? () {
            FocusManager.instance.primaryFocus?.unfocus();
            onPressed!.call();
          }
        : null;

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: nonNullOnPressed,
        child: Text(title),
      ),
    );
  }
}
