import 'package:cloudless/core/config/time_limit_values.dart';
import 'package:cloudless/core/features/time_limit/domain/hooks/use_time_limit.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class HomeTimeLimitToggle extends HookConsumerWidget
    with MainLayout, HomeLayout {
  const HomeTimeLimitToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final timeLimitData = useTimeLimit(ref);

    if (timeLimitData.timeLimit == null) {
      return const SizedBox.shrink();
    }

    final currentMinutes = timeLimitData.timeLimit!.minutes;
    final isShortLimit = currentMinutes == TimeLimitValues.getShortMinutes();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          timeLimitToggleContainerBorderRadius,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(timeLimitToggleContainerPadding),
        child: GestureDetector(
          onTap: timeLimitData.isLoading
              ? null
              : () async {
                  final success = await timeLimitData.toggleTimeLimit();
                  if (!success && context.mounted) {
                    MainAlert.showError(
                      context: context,
                      title: translator.translate(
                        'pages.home.time_limit.alert.cannot_decrease.title',
                      ),
                      content: translator.translate(
                        'pages.home.time_limit.alert.cannot_decrease.content',
                      ),
                      buttonText: translator.translate(
                        'components.alert.confirm_button',
                      ),
                    );
                  }
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: timeLimitToggleItemHorizontalPadding,
                  vertical: timeLimitToggleItemVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: isShortLimit
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    timeLimitToggleItemBorderRadius,
                  ),
                ),
                child: Text(
                  translator.translate(
                    'pages.home.time_limit.minutes_format',
                    arguments: {'minutes': TimeLimitValues.getShortMinutes().toString()},
                  ),
                  style: textTheme.labelMedium?.copyWith(
                    color: isShortLimit
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: timeLimitToggleItemHorizontalPadding,
                  vertical: timeLimitToggleItemVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: !isShortLimit
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    timeLimitToggleItemBorderRadius,
                  ),
                ),
                child: Text(
                  translator.translate(
                    'pages.home.time_limit.minutes_format',
                    arguments: {'minutes': TimeLimitValues.getLongMinutes().toString()},
                  ),
                  style: textTheme.labelMedium?.copyWith(
                    color: !isShortLimit
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
