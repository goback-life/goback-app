import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Minimum lockout duration in minutes.
/// Override at build time: `--dart-define=MIN_LOCKOUT_MINUTES=1`
const _kMinLockoutMinutes = int.fromEnvironment(
  'MIN_LOCKOUT_MINUTES',
  defaultValue: 60,
);

class ManualLockoutDialog extends HookConsumerWidget with MainLayout {
  const ManualLockoutDialog({super.key});

  /// Result type: either a timed lockout or an NFC venue scan request.
  ///
  /// When [nfcScan] is true, [duration] and [actionText] are null.
  static Future<({Duration? duration, String? actionText, bool nfcScan})?> show(
    BuildContext context,
  ) {
    // Prefer the passed context; fall back to the root navigator if it lacks
    // a Navigator ancestor (can happen after hot restart with FeedView).
    final hasNavigator = Navigator.maybeOf(context) != null;
    final dialogContext = hasNavigator
        ? context
        : startupNavigatorKey.currentContext!;
    return showDialog<({Duration? duration, String? actionText, bool nfcScan})>(
      context: dialogContext,
      useRootNavigator: hasNavigator,
      barrierDismissible: true,
      builder: (context) => const ManualLockoutDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final selectedHours = useState<int>(_kMinLockoutMinutes < 60 ? 0 : 1);
    final selectedMinutes = useState<int>(
      _kMinLockoutMinutes < 60 ? _kMinLockoutMinutes : 0,
    );
    final activityController = useTextEditingController();
    final selectedPreset = useState<String?>(null);

    // Preset activities: key → emoji
    const presets = {
      'sport': '\u{1F3C3}',
      'music': '\u{1F3B5}',
      'friends': '\u{1F91D}',
      'relax': '\u{1F9D8}',
      'studying': '\u{1F4DA}',
    };

    // Calculate total duration
    final totalDuration = Duration(
      hours: selectedHours.value,
      minutes: selectedMinutes.value,
    );

    final isValid = totalDuration.inMinutes >= _kMinLockoutMinutes;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
              const SizedBox(height: 20),
              // NFC venue scan option
              OutlinedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pop((duration: null, actionText: null, nfcScan: true)),
                icon: const Icon(Icons.nfc_rounded),
                label: const Text('Scan GoBack Tag'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: colorScheme.onSurface.withValues(alpha: 0.12)),
              const SizedBox(height: 16),
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
                        initialItem: _kMinLockoutMinutes < 60
                            ? selectedHours.value
                            : selectedHours.value - 1,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        selectedHours.value = _kMinLockoutMinutes < 60
                            ? index
                            : index + 1;
                      },
                      children: List.generate(
                        _kMinLockoutMinutes < 60 ? 10 : 9,
                        (index) {
                          final hr = _kMinLockoutMinutes < 60
                              ? index
                              : index + 1;
                          return Center(
                            child: Text(
                              '$hr ${hr == 1 ? 'hr' : 'hrs'}',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Minutes picker
                  SizedBox(
                    width: 80,
                    height: 150,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem:
                            (_kMinLockoutMinutes < 60
                                    ? [0, 1, 2, 3, 5, 10, 15, 30, 45]
                                    : [0, 15, 30, 45])
                                .indexOf(selectedMinutes.value),
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        selectedMinutes.value = (_kMinLockoutMinutes < 60
                            ? [0, 1, 2, 3, 5, 10, 15, 30, 45]
                            : [0, 15, 30, 45])[index];
                      },
                      children:
                          (_kMinLockoutMinutes < 60
                                  ? [0, 1, 2, 3, 5, 10, 15, 30, 45]
                                  : [0, 15, 30, 45])
                              .map((minutes) {
                                return Center(
                                  child: Text(
                                    '$minutes min',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Preset activity chips — horizontal scroll
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final e = presets.entries.elementAt(index);
                    final isSelected = selectedPreset.value == e.key;
                    final label = translator.translate(
                      'pages.manual_lockout.dialog.activities.${e.key}',
                    );
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          selectedPreset.value = null;
                          activityController.clear();
                        } else {
                          selectedPreset.value = e.key;
                          activityController.text = label;
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.15),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.value, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: textTheme.bodyMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Custom activity text field
              TextField(
                controller: activityController,
                maxLength: 20,
                textAlign: TextAlign.center,
                onChanged: (_) => selectedPreset.value = null,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: translator.translate(
                    'pages.manual_lockout.dialog.activity_hint',
                  ),
                  hintStyle: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  counterStyle: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                        final text = activityController.text.trim();
                        Navigator.of(context).pop((
                          duration: duration,
                          actionText: text.isEmpty ? null : text,
                          nfcScan: false,
                        ));
                      }
                    : null,
                label: Text(
                  translator.translate('pages.manual_lockout.dialog.confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
