# Dedecube Logger

Dedecube Logger is a lightweight and flexible logging package for Flutter applications based on Talker.

## Installation

Add `dedecube_logger` to your dependencies in `pubspec.yaml`:

```yaml
dependencies:
  dedecube_logger:
    git:
      url: git@github.com:dedecube/dedecube-logger.git
      ref: v0.0.25
```

## How to use

### Initialization

Ensure to set the `LOG_SEVERITY` in your environment configuration file (e.g. .env). If not set, logs will not be displayed.

```dart
import 'package:dedecube_logger/dedecube_logger.dart';
import 'package:get_it/get_it.dart';

final loggerConfig = LoggerConfig(
    logSeverity: environment.tryGetString('LOG_SEVERITY'),
);

GetIt.I.registerSingleton<LoggerContract>(Logger(loggerConfig));
```

### Configuration

You can dynamically update the logger's configuration:

```dart
final newConfig = LoggerConfig(
    logSeverity: environment.tryGetString('LOG_SEVERITY'),
);
logger.config = newConfig;
```

### Logging

You can use the logger as follows:

```dart
import 'package:dedecube_logger/dedecube_logger.dart';

logger.info('This is an informational message.');
logger.warning('This is a warning message.', arguments: {'userId': '12345', 'action': 'update'});  
logger.error('This is an error message.', exception: e, stackTrace: stackTrace);
logger.critical('This is a critical message.');

```

## License

Dedecube Logger is released under the [MIT License](LICENSE).
