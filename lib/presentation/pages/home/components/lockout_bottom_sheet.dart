import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/nav_overlay/nav_overlay_wrapper.dart';
import 'package:cloudless/presentation/pages/home/components/lockout_activity_chips.dart';
import 'package:cloudless/presentation/pages/home/components/lockout_duration_ring.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Minimum lockout duration in minutes.
/// Override at build time: `--dart-define=MIN_LOCKOUT_MINUTES=1`
const _kMinLockoutMinutes = int.fromEnvironment(
  'MIN_LOCKOUT_MINUTES',
  defaultValue: 30,
);

class LockoutBottomSheet extends HookWidget {
  const LockoutBottomSheet({super.key});

  /// Shows the lockout bottom sheet and returns the user's selection.
  ///
  /// Returns `null` if dismissed. When [nfcScan] is `true`, [duration] and
  /// [actionText] are `null`.
  static Future<({Duration? duration, String? actionText, bool nfcScan})?> show(
    BuildContext context,
  ) async {
    NavOverlayWrapper.suppress.value = true;
    try {
      return await Navigator.of(
        context,
        rootNavigator: true,
      ).push<({Duration? duration, String? actionText, bool nfcScan})>(
        PageRouteBuilder(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (ctx, _, __) => Material(
            color: Colors.transparent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(ctx).pop(),
              child: ColoredBox(
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () {},
                    child: const LockoutBottomSheet(),
                  ),
                ),
              ),
            ),
          ),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        ),
      );
    } finally {
      NavOverlayWrapper.suppress.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = useState(const Duration(hours: 1));
    final selectedPreset = useState<String?>(null);
    final customText = useState<String?>(null);

    final isValid = duration.value.inMinutes >= _kMinLockoutMinutes;

    String? resolveActionText() {
      if (customText.value != null) return customText.value;
      if (selectedPreset.value == null) return null;
      final key = selectedPreset.value!;
      return key[0].toUpperCase() + key.substring(1);
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle (visual only — sheet drag is disabled)
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  'GO BACK',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 24),
                // Duration ring
                LockoutDurationRing(
                  duration: duration.value,
                  onDurationChanged: (d) => duration.value = d,
                  minMinutes: _kMinLockoutMinutes,
                ),
                if (!isValid) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Minimum $_kMinLockoutMinutes minutes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 28),
                // Activity chips
                LockoutActivityChips(
                  selectedPreset: selectedPreset.value,
                  customText: customText.value,
                  onPresetSelected: (key) {
                    selectedPreset.value = key;
                    customText.value = null;
                  },
                  onCustomTextChanged: (text) {
                    customText.value = text;
                    selectedPreset.value = null;
                  },
                ),
                const SizedBox(height: 24),
                // Go Back CTA
                CallToAction.primary.filled(
                  action: isValid
                      ? () => Navigator.of(context).pop((
                          duration: duration.value,
                          actionText: resolveActionText(),
                          nfcScan: false,
                        ))
                      : null,
                  label: const Text('Go Back'),
                ),
                const SizedBox(height: 14),
                // NFC link
                GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).pop((duration: null, actionText: null, nfcScan: true)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'At a venue? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                        Text(
                          'Scan Tag',
                          style: TextStyle(
                            fontSize: 14,
                            color: MainColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
