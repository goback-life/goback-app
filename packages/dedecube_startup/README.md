
# Dedecube Startup

Dedecube Startup is a robust Flutter initialization package designed to ensure a seamless and reliable application startup process. It includes built-in loading screens, retry mechanisms, and simplifies handling of initialization states and errors.

## Installation

Add `dedecube_startup` to your dependencies in `pubspec.yaml`:

```yaml
dependencies:
  dedecube_startup:
    git:
      url: git@github.com:dedecube/dedecube-startup.git
      ref: v0.0.32
```

## Configuration

Dedecube Startup can be customized by creating a custom [StartupConfig] using the following parameters:

- **routes**: A list of [Routable] objects that define the available routes in the application.
- **supportedThemes**: A list of [Themable] objects representing the themes supported by the application.  
- **initialTheme**: The theme that is used as the default when the application starts.
- **loadingPage**: The widget displayed while the application is loading or initializing resources.  
- **errorPage**: The widget displayed when an error occurs during initialization.
- **appBuilder**: A builder function to wrap the MaterialApp with custom widgets (see App Builder section below).
- **localizationsDelegates**: Additional localization delegates to be added to the MaterialApp (see Localization section below).

## How to Use

### Basic Initialization

Set up Dedecube Startup in your main.dart:

```dart
  Startup(startupConfig).initialize();
```

⚠️ **IMPORTANT**: For this package to work, the following settings must be added to `pubspec.yaml`:

```yaml
  assets:
    - assets/translations/
    - path: .env
```

## App Builder

The `appBuilder` parameter allows you to wrap the MaterialApp content with custom widgets. This function is called within the MaterialApp's builder, giving you access to the proper context with localization, theme, and other inherited widgets. This is useful for integrating third-party packages that need to be at a high level in your app widget tree.

### Basic Usage

```dart
Startup(
  StartupConfig(
    routes: [
      // Your routes here
    ],
    appBuilder: (context, child) => MyCustomWrapper(
      child: child,
    ),
  ),
).initialize();
```

### Example with StreamChat

```dart
Startup(
  StartupConfig(
    routes: [
      // Your routes here  
    ],
    appBuilder: (context, child) => StreamChat(
      client: streamChatClient,
      child: child,
      streamChatThemeData: StreamChatThemeData.fromTheme(
        Theme.of(context),
      ),
    ),
  ),
).initialize();
```

## Custom Localization Delegates

The `localizationsDelegates` parameter allows you to add custom localization delegates to the MaterialApp. These will be combined with the default translator localization delegates.

### Adding Custom Delegates

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

Startup(
  StartupConfig(
    routes: [
      // Your routes here
    ],
    localizationsDelegates: [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      // Add your custom delegates here
    ],
  ),
).initialize();
```

## Lifecycle Callback Methods

Dedecube Startup provides lifecycle callback methods:

### `onInitializeStart`

- **Description**: Registers a callback to be executed when the startup initialization starts.
- **Example usage**:

```
Startup(startupConfig).initialize().onInitializeStart((ref) { });
```

### `onInitializeComplete`

- **Description**: Registers a callback to be invoked when the initialization is complete.
- **Example usage**:

```dart
Startup(startupConfig).initialize(). onInitializeComplete((ref) { });
```

## License

Dedecube Startup is released under the [MIT License](LICENSE).
