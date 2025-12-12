
# Dedecube Themify

Dedecube Themify is a Flutter package for advanced theme management. It provides a flexible and modular system to customize colors, typography, and UI styling, supporting dynamic theme switching and light/dark modes.

## Installation

Add `dedecube_themify` to your dependencies in `pubspec.yaml`:

```yaml
dependencies:
  dedecube_themify:
    git:
      url: git@github.com:dedecube/dedecube-themify.git
      ref: v0.0.17
```

> **Note:** Using `dedecube_startup`, the `dedecube_themify` package is already included.

## Define Colors

You can define a custom colors class to centrally manage your application's color palette. This is especially useful for ensuring that your colors are consistent throughout your project and can be easily maintained or updated.

For example, you might create a `MainColors`:

```dart
class MainColors {
  static const Color white = Color(0xFFFFFFFF);

  static const Color green500 = Color(0xFF3CEB9B);

  static const Color red500 = Color(0xFFED6A5F);
  static const Color red600 = Color(0xFFFF382B);

  static const Color blue300 = Color(0xFF8199FC);
  static const Color blue500 = Color(0xFF5772E3);
  static const Color blue600 = Color(0xFF4256A8);
  static const Color blue700 = Color(0xFF35426A);

  static const Color grey100 = Color(0xFFF6F6F6);
  static const Color grey200 = Color(0xFFC4C4C6);
  static const Color grey500 = Color(0xFF2A3142);
  static const Color grey600 = Color(0xFF222736);
}
```

If you need assistance with mapping your custom colors to a standardized palette, consider using the [Find Nearest Tailwind Colour](https://find-nearest-tailwind-colour.netlify.app) tool to quickly determine the closest Tailwind CSS color value.

## Defining Themes

Define your custom themes by creating `Themable`:

```dart
import 'package:dedecube_themify/dedecube_themify.dart';

class MainTheme implements Themable {
  @override
  ColorScheme get colorScheme {
    return ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: MainColors.blue300,
    );
  }

  @override
  ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.light,
      primaryColorLight: MainColors.white,
    );
  }
}
```

### How to properly generate the `ColorScheme`

To create a `ColorScheme` consistent with your design (e.g., from Figma), we recommend using the official Material tool:

👉 [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)

1. Go to the website and enable **"Color Match"**.
2. Input your primary, secondary, tertiary, error, etc. colors based on your design.
3. Once the scheme is generated, you can copy and adapt it in your code.
4. If some colors are not faithful to the design (e.g., from Figma), you can manually override them using your own references from `MainColors`.

The table below shows examples of how to use these properties:

| Color                    | Typical Use                                                                 |
|--------------------------|------------------------------------------------------------------------------|
| `primary`                | For text, icons, or small interactive elements                              |
| `onPrimary`              | For text/icons placed on elements with `primary` as background              |
| `primaryContainer`       | For backgrounds of cards or larger UI blocks                                |
| `onPrimaryContainer`     | For text/icons on top of `primaryContainer`                                 |
| `surface`                | General background for entire screens                                       |
| `onSurface`              | For text/icons placed on `surface` backgrounds                                        |
| `surfaceVariant`         | Background for inactive/disabled elements                                   |
| `outline`                | Borders for active elements                                                 |
| `outlineVariant`         | Borders for inactive/disabled elements                                      |

Here is an example of how to implement it:

```dart
class MainTheme implements Themable {
  @override
  ColorScheme get colorScheme {
    return const ColorScheme(
      brightness: Brightness.light,
      // primaries
      primary: MainColors.blue700,
      surfaceTint: MainColors.blue700,
      onPrimary: MainColors.white,
      primaryContainer: MainColors.blue600,
      onPrimaryContainer: Color(0xFFF6FEFF),
      // secondaries
      secondary: Color(0xFF016874),
      onSecondary: MainColors.white,
      secondaryContainer: MainColors.blue500,
      onSecondaryContainer: MainColors.white,
      // tertiaries
      tertiary: MainColors.yellow500,
      onTertiary: MainColors.white,
      tertiaryContainer: MainColors.yellow600,
      onTertiaryContainer: MainColors.white,
      // error
      error: MainColors.red500, // call to actions
      onError: MainColors.white,
      errorContainer: MainColors.red400, // banners
      onErrorContainer: MainColors.white,
      // surface
      surface: MainColors.white,
      onSurface: MainColors.black,
      onSurfaceVariant: MainColors.grey500,
      // outline
      outline: MainColors.grey500,
      outlineVariant: MainColors.grey400,
      // shadows and scrims
      shadow: MainColors.black,
      scrim: MainColors.black,
      // containers
      surfaceContainerLowest: MainColors.white,
      // avatar placeholder
      surfaceContainerLow: MainColors.grey100,
      // cards and tab bar
      surfaceContainer: MainColors.grey200,
      // group chat background and chat action bar
      surfaceContainerHigh: MainColors.grey300,
      // videos background
      surfaceContainerHighest: MainColors.grey400,
      // free banner
      tertiaryFixedDim: MainColors.yellow600,
      onTertiaryFixedVariant: MainColors.white,
      // unused
      inverseSurface: Color(0xFF2D3132),
      inversePrimary: Color(0xFF7CD4E0),
      primaryFixed: Color(0xFF99F0FC),
      onPrimaryFixed: Color(0xFF001F23),
      primaryFixedDim: Color(0xFF7CD4E0),
      onPrimaryFixedVariant: Color(0xFF004f56),
      secondaryFixed: Color(0xFFA2EFFC),
      onSecondaryFixed: Color(0xFF001f24),
      secondaryFixedDim: Color(0xFF85D2E0),
      onSecondaryFixedVariant: Color(0xFF004F58),
      tertiaryFixed: Color(0xFFFFE330),
      onTertiaryFixed: Color(0xFF211C00),
      surfaceDim: Color(0xFFD7DBDB),
      surfaceBright: Color(0xFFF7FAFA),
    );
  }

  @override
  ThemeData get themeData {
    return ThemeData(
      textTheme: MainTextTheme.theme(colorScheme),
    );
  }
}
```

## Advanced Theme Customization

For themes with complex customizations—such as detailed configurations for `appBarTheme`, `textTheme`, etc.—it is recommended to encapsulate this logic in separate component classes within a dedicated `components` folder. For example, if your theme overrides the `themeData` getter like this:

```dart
@override
ThemeData get themeData {
  return ThemeData(
    brightness: Brightness.dark,
    appBarTheme: MacosAppBarTheme.theme(colorScheme),
  );
}
```

You can create a class like this to encapsulate the app bar styling:

```dart
static AppBarTheme theme(ColorScheme? colorScheme) {
  return AppBarTheme(
    backgroundColor: colorScheme?.primary,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );
}
```

## Switching Themes

You can dynamically switch themes within your app easily:

```dart
Themify.of(context).setTheme(CustomTheme);
```

> **Note:** The theme you pass (e.g. `CustomTheme`) must be included in the list of supported themes defined in your configuration. Otherwise, a `ThemifyThemeNotFoundException` will be thrown.

## Accessing Current Theme

Access the current theme data anywhere in your app:

```dart
final themeData = Themify.of(context).currentTheme;
final primaryColor = themeData.primaryColor;
```

## Default Theme

If no theme is explicitly set in your startup configuration, the `DefaultTheme` will be automatically applied.

If you need to force the use of the default theme for a specific part of your application (for example, in a dedicated screen), you can wrap your widget tree with the `DefaultThemeWrapper`. This ensures that the default theme is applied regardless of the current theme settings.

```dart
import 'package:flutter/material.dart';
import 'package:dedecube_themify/dedecube_themify.dart';

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultThemeWrapper(
      builder: (context) {
        return Scaffold(
          body: Center(
            child: Text('This screen always uses the default theme.'),
          ),
        );
      },
    );
  }
}
```

## Layout

Dedecube Themify also supports layout configurations for your UI components. Layout configurations control structural properties such as padding, spacing, dimensions, border radius, and others. There is a default layout configuration available out-of-the-box, but you can also extend and customize it to suit your design needs.

For example, you can create a custom layout by extending the `Layout` and overriding the `config` getter to provide a default configuration. You can also add additional custom properties specific to your application:

```dart
class HomeLayout extends Layout {
  HomeLayout();

  // Custom properties: these are additional settings specific to your layout needs.
  final double spaceBetweenButtons = 10;
  final ButtonLayout buttonLayout = ButtonLayout();

  // Default layout configuration.
  @override
  LayoutConfig get config {
    return LayoutConfig(
      borderRadius: 10,
      // Other default properties can be set as needed.
    );
  }
}
```

In addition, you can create an extension of the layout configuration for specific UI components. For example, if you want to customize the layout of buttons with additional properties—such as an elevation attribute—you could define a custom `ButtonLayout` class:

```dart
class ButtonLayout extends Layout {
  ButtonLayout();

  // Custom property for button-specific layout.
  final double elevation = 10;

  @override
  LayoutConfig get config {
    return LayoutConfig(
      borderRadius: 10,
      // Additional default properties for buttons can be added here.
    );
  }
}
```

Using a layout is simple. For example, you can create an instance with:

```dart
final layout = HomeLayout();
```

⚠️ **IMPORTANT** Layout configurations can be applied across entire pages, views, or components. However, when a styling property is shared among multiple elements, the theme takes precedence by default. This ensures that components consistently adhere to the overall styling defined by the theme, while the layout provides supplementary details.

## License

Dedecube Themify is released under the [MIT License](LICENSE).
