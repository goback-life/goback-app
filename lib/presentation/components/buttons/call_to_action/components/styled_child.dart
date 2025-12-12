part of '../call_to_action.dart';

class _CallToActionStyledChild extends StatelessWidget {
  const _CallToActionStyledChild({
    required this.foreground,
    required this.child,
  });

  final Color foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style.merge(
            theme.textTheme.labelMedium!.copyWith(
              color: foreground,
            ),
          ),
      child: IconTheme(
        data: IconTheme.of(context).copyWith(color: foreground),
        child: child,
      ),
    );
  }
}
