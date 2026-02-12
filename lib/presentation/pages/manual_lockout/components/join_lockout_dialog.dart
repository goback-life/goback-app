import 'package:cloudless/core/features/lockout/domain/models/lockout_session_model.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class JoinLockoutDialog extends StatelessWidget with MainLayout {
  const JoinLockoutDialog({super.key, required this.session});

  final LockoutSessionModel session;

  static Future<bool?> show(BuildContext context, LockoutSessionModel session) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => JoinLockoutDialog(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final timeRemaining = _formatTimeRemaining(session.endsAt);

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AppGlassContainer(
        config: const GlassConfig(
          variant: GlassVariant.regular,
          cornerRadius: 16,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translator.translate(
                'pages.manual_lockout.friends_locked_out.join_dialog.title',
                context: context,
                arguments: {'username': session.username ?? ''},
              ),
              style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              translator.translate(
                'pages.manual_lockout.friends_locked_out.join_dialog.description',
                context: context,
                arguments: {'time': timeRemaining},
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: CallToAction.secondary.outlined(
                    action: () => Navigator.of(context).pop(false),
                    label: Text(
                      translator.translate(
                        'pages.manual_lockout.friends_locked_out.join_dialog.cancel',
                      ),
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CallToAction.primary.filled(
                    action: () => Navigator.of(context).pop(true),
                    label: Text(
                      translator.translate(
                        'pages.manual_lockout.friends_locked_out.join_dialog.confirm',
                      ),
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatTimeRemaining(DateTime endsAt) {
    final now = DateTime.now();
    final remaining = endsAt.difference(now);

    if (remaining.isNegative) return '0m';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
