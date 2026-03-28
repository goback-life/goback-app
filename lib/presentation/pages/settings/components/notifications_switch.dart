import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/settings/components/notifications_switch_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class NotificationSwitch extends HookConsumerWidget
    with MainLayout, NotificationSwitchLayout {
  const NotificationSwitch({super.key, this.value = true, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );

    final animation = useMemoized(
      () =>
          CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
      [animationController],
    );

    useEffect(() {
      if (value) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [value]);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return AppGlassContainer(
          config: GlassConfig(
            variant: GlassVariant.regular,
            cornerRadius: switchBorderRadius,
          ),
          child: SizedBox(
            width: switchWidth,
            height: switchHeight,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: value ? thumbActiveLeft : thumbInactiveLeft,
                  top: thumbTop,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerLow,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
