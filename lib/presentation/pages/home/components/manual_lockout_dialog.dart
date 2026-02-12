import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ManualLockoutDialog extends HookConsumerWidget with MainLayout {
  const ManualLockoutDialog({super.key});

  static Future<Duration?> show(BuildContext context) {
    return showDialog<Duration>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ManualLockoutDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final selectedHours = useState<int>(0);
    final selectedMinutes = useState<int>(2);

    // Calculate total duration
    final totalDuration = Duration(
      hours: selectedHours.value,
      minutes: selectedMinutes.value,
    );

    // Validate: must be > 1 hour
    // Validate: must be >= 2 minutes
    final isValid = totalDuration.inMinutes >= 2;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translator.translate('pages.manual_lockout.dialog.title'),
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Text(
              translator.translate('pages.manual_lockout.dialog.description'),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Time pickers
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours picker
                SizedBox(
                  width: 80,
                  height: 150,
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedHours.value,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      selectedHours.value = index;
                    },
                    children: List.generate(10, (index) {
                      final hours = index;
                      return Center(
                        child: Text(
                          hours == 0
                              ? '0 hrs'
                              : '$hours ${hours == 1 ? 'hr' : 'hrs'}',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                // Minutes picker
                SizedBox(
                  width: 80,
                  height: 150,
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: [2, 0, 15, 30, 45].indexOf(selectedMinutes.value),
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      selectedMinutes.value = [2, 0, 15, 30, 45][index];
                    },
                    children: [2, 0, 15, 30, 45].map((minutes) {
                      return Center(
                        child: Text(
                          '$minutes min',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!isValid)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  translator.translate('pages.manual_lockout.dialog.error'),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Buttons
            CallToAction.primary.filled(
              action: isValid
                  ? () {
                      final duration = Duration(
                        hours: selectedHours.value,
                        minutes: selectedMinutes.value,
                      );
                      Navigator.of(context).pop(duration);
                    }
                  : null,
              label: Text(
                translator.translate('pages.manual_lockout.dialog.confirm'),
                style: textTheme.titleMedium?.copyWith(
                  color: isValid
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

