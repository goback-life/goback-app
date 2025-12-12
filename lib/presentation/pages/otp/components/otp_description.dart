import 'package:flutter/material.dart';

class OtpDescription extends StatelessWidget {
  const OtpDescription({required this.number, required this.text, super.key});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            textAlign: TextAlign.start,
            text: TextSpan(
              text: text,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              children: [
                TextSpan(
                  text: number,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
