import 'package:flutter/material.dart';

class LinkTextStyle extends ThemeExtension<LinkTextStyle> {
  const LinkTextStyle();

  TextStyle style(ThemeData theme) => TextStyle(
    color: theme.colorScheme.primary,
    decorationColor: theme.colorScheme.primary,
    decoration: TextDecoration.underline,
    fontWeight: FontWeight.bold,
  );
  @override
  LinkTextStyle copyWith() {
    return const LinkTextStyle();
  }

  @override
  LinkTextStyle lerp(LinkTextStyle? other, double t) {
    if (other is! LinkTextStyle) {
      return this;
    }
    return const LinkTextStyle();
  }
}

extension GetLinkTextStyleFromThemeData on ThemeData {
  TextStyle get linkTextStyle => extension<LinkTextStyle>()!.style(this);
}

extension GetLinkTextStyleFromTextStyle on TextStyle {
  TextStyle toLinkStyle(ThemeData theme) => merge(theme.linkTextStyle);
}
