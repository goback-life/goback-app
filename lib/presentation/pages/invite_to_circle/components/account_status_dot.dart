import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';

/// Small colored dot indicating whether a phone number has a goback account.
/// Accent = has account, dimmed onSurface = no account.
class AccountStatusDot extends StatelessWidget {
  const AccountStatusDot({super.key, required this.hasAccount});

  final bool hasAccount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: hasAccount
            ? MainColors.accent
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
