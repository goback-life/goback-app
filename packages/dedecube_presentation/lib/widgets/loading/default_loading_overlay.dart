import 'package:flutter/material.dart';

class DefaultLoadingOverlay extends StatelessWidget {
  const DefaultLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.black.withValues(alpha: .3),
      child: SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
