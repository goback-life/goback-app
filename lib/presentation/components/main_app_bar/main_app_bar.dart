import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/main_app_bar/main_app_bar_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class MainAppBar extends HookConsumerWidget with MainLayout, MainAppBarLayout {
  const MainAppBar({
    required this.title,
    super.key,
    this.rightWidget,
    this.titleStyle,
  });

  final String title;
  final Widget? rightWidget;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    Widget? backButton;
    if (parentRoute?.impliesAppBarDismissal ?? false) {
      backButton = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => router.pop(),
        child: SizedBox(
          width: iconSize + 10,
          height: iconSize + 10,
          child: Center(
            child: Assets.svg.back.render(height: iconSize, width: iconSize),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                if (backButton != null)
                  Positioned(left: 0, top: 0, bottom: 0, child: backButton),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: appBarHeight),
                  child: Center(
                    child: Text(
                      title,
                      style:
                          titleStyle ??
                          textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
                if (rightWidget != null)
                  Positioned(right: 0, top: 0, bottom: 0, child: rightWidget!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget customAction({
    required Widget icon,
    required VoidCallback onTap,
    double? size,
  }) {
    return Builder(
      builder: (context) {
        const mainAppBar = MainAppBar(title: '');

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          child: SizedBox(
            height: mainAppBar.rightIconSize + 14,
            width: mainAppBar.rightIconSize + 14,
            child: Center(child: icon),
          ),
        );
      },
    );
  }

  static Widget multipleActions(List<Widget> actions, {double spacing = 8.0}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .expand((action) => [action, SizedBox(width: spacing)])
          .take(actions.length * 2 - 1)
          .toList(),
    );
  }
}
