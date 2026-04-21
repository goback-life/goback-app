// ignore_for_file: one_class_per_file
part of '../call_to_action.dart';

typedef CTAColors = ({Color background, Color foreground, Color outline});

abstract class CallToActionTheme {
  const CallToActionTheme();

  static const regular = RegularCallToActionTheme();
  static const danger = DangerCallToActionTheme();
  static const primary = PrimaryCallToActionTheme();
  static const secondary = SecondaryCallToActionTheme();
  static const high = HighCallToActionTheme();
  static const background = BackgroundCallToActionTheme();

  CTAColors getActiveColors(
    BuildContext context,
    ThemeData theme,
    CallToActionMode mode,
  );

  CTAColors getInactiveColors(
    BuildContext context,
    ThemeData theme,
    CallToActionMode mode,
  ) {
    final colors = theme.colorScheme;
    return switch (mode) {
      CallToActionMode.filled => (
        background: colors.onPrimaryContainer.withValues(alpha: 0.1),
        foreground: colors.outline,
        outline: colors.outline.withValues(alpha: 0),
      ),
      CallToActionMode.empty => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.onSurfaceVariant,
        outline: colors.surface.withValues(alpha: 0),
      ),
      CallToActionMode.outlined => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.onSurfaceVariant,
        outline: colors.onSurfaceVariant,
      ),
      CallToActionMode.filledOutlined => (
        background: colors.surfaceContainerHigh,
        foreground: colors.onSurfaceVariant,
        outline: colors.onSurfaceVariant,
      ),
    };
  }
}

class RegularCallToActionTheme extends CallToActionTheme {
  const RegularCallToActionTheme();

  @override
  CTAColors getActiveColors(context, theme, mode) {
    final colors = theme.colorScheme;
    return switch (mode) {
      CallToActionMode.filled => (
        background: colors.inverseSurface,
        foreground: colors.onInverseSurface,
        outline: colors.inverseSurface.withValues(alpha: 0),
      ),
      CallToActionMode.empty => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.onSurface,
        outline: colors.surface.withValues(alpha: 0),
      ),
      CallToActionMode.outlined => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.onSurface,
        outline: colors.onSurface,
      ),
      CallToActionMode.filledOutlined => (
        background: colors.inverseSurface,
        foreground: colors.onInverseSurface,
        outline: colors.onInverseSurface,
      ),
    };
  }
}

class HighCallToActionTheme extends CallToActionTheme {
  const HighCallToActionTheme();

  @override
  CTAColors getActiveColors(context, theme, mode) {
    final colors = theme.colorScheme;
    return switch (mode) {
      CallToActionMode.filled => (
        background: colors.surfaceContainerHigh,
        foreground: colors.onSurface,
        outline: colors.surfaceContainerHigh.withValues(alpha: 0),
      ),
      CallToActionMode.empty => (
        background: colors.surfaceContainerHigh.withValues(alpha: 0),
        foreground: colors.onSurface,
        outline: colors.surfaceContainerHigh.withValues(alpha: 0),
      ),
      CallToActionMode.outlined => (
        background: colors.surfaceContainerHigh.withValues(alpha: 0),
        foreground: colors.onSurface,
        outline: colors.onSurface,
      ),
      CallToActionMode.filledOutlined => (
        background: colors.surfaceContainerHigh,
        foreground: colors.onSurface,
        outline: colors.onSurface,
      ),
    };
  }
}

class BackgroundCallToActionTheme extends CallToActionTheme {
  const BackgroundCallToActionTheme();

  @override
  CTAColors getActiveColors(context, theme, mode) {
    final colors = theme.colorScheme;
    return switch (mode) {
      CallToActionMode.filled => (
        background: theme.scaffoldBackgroundColor,
        foreground: colors.onSurface,
        outline: theme.scaffoldBackgroundColor.withValues(alpha: 0),
      ),
      CallToActionMode.empty => (
        background: theme.scaffoldBackgroundColor.withValues(alpha: 0),
        foreground: colors.onSurface,
        outline: theme.scaffoldBackgroundColor.withValues(alpha: 0),
      ),
      CallToActionMode.outlined => (
        background: theme.scaffoldBackgroundColor.withValues(alpha: 0),
        foreground: colors.onSurface,
        outline: colors.onSurface,
      ),
      CallToActionMode.filledOutlined => (
        background: theme.scaffoldBackgroundColor,
        foreground: colors.onSurface,
        outline: colors.onSurface,
      ),
    };
  }
}

class PrimaryCallToActionTheme extends CallToActionTheme {
  const PrimaryCallToActionTheme();

  @override
  CTAColors getActiveColors(context, theme, mode) {
    final colors = theme.colorScheme;
    return switch (mode) {
      CallToActionMode.filled => (
        background: colors.primaryContainer,
        foreground: colors.onSurface,
        outline: colors.primaryContainer.withValues(alpha: 0),
      ),
      CallToActionMode.empty => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.primary,
        outline: colors.surface.withValues(alpha: 0),
      ),
      CallToActionMode.outlined => (
        background: colors.surface,
        foreground: colors.onSurface,
        outline: colors.surfaceContainerLow,
      ),
      CallToActionMode.filledOutlined => (
        background: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
        outline: colors.onPrimaryContainer,
      ),
    };
  }
}

class SecondaryCallToActionTheme extends CallToActionTheme {
  const SecondaryCallToActionTheme();

  @override
  CTAColors getActiveColors(context, theme, mode) {
    final colors = theme.colorScheme;
    return switch (mode) {
      CallToActionMode.filled => (
        background: colors.surface,
        foreground: colors.onSurface,
        outline: colors.onSurface,
      ),
      CallToActionMode.empty => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.secondary,
        outline: colors.surface.withValues(alpha: 0),
      ),
      CallToActionMode.outlined => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.outline,
        outline: colors.primaryContainer,
      ),
      CallToActionMode.filledOutlined => (
        background: colors.secondaryContainer,
        foreground: colors.onSecondaryContainer,
        outline: colors.onSecondaryContainer,
      ),
    };
  }
}

class TertiaryCallToActionTheme extends CallToActionTheme {
  const TertiaryCallToActionTheme();

  @override
  CTAColors getActiveColors(context, theme, mode) {
    final colors = theme.colorScheme;
    return switch (mode) {
      CallToActionMode.filled => (
        background: colors.tertiaryContainer,
        foreground: colors.onTertiaryContainer,
        outline: colors.tertiaryContainer.withValues(alpha: 0),
      ),
      CallToActionMode.empty => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.tertiary,
        outline: colors.surface.withValues(alpha: 0),
      ),
      CallToActionMode.outlined => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.tertiary,
        outline: colors.tertiary,
      ),
      CallToActionMode.filledOutlined => (
        background: colors.tertiaryContainer,
        foreground: colors.onTertiaryContainer,
        outline: colors.onTertiaryContainer,
      ),
    };
  }
}

class DangerCallToActionTheme extends CallToActionTheme {
  const DangerCallToActionTheme();

  @override
  CTAColors getActiveColors(context, theme, mode) {
    final colors = theme.colorScheme;
    return switch (mode) {
      CallToActionMode.filled => (
        background: colors.error,
        foreground: colors.onErrorContainer,
        outline: colors.secondaryContainer.withValues(alpha: 0),
      ),
      CallToActionMode.empty => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.error,
        outline: colors.surface.withValues(alpha: 0),
      ),
      CallToActionMode.outlined => (
        background: colors.surface.withValues(alpha: 0),
        foreground: colors.error,
        outline: colors.error,
      ),
      CallToActionMode.filledOutlined => (
        background: colors.errorContainer,
        foreground: colors.onErrorContainer,
        outline: colors.onErrorContainer,
      ),
    };
  }
}
