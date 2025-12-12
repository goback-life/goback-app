# Dedecube Environment

Dedecube Environment is a lightweight and flexible configuration management library.

## Installation

Add `dedecube_environment` to your dependencies in `pubspec.yaml`:

```yaml
dependencies:
  dedecube_environment:
    git:
      url: git@github.com:dedecube/dedecube-environment.git
      ref: v0.0.23
```

## How to use

### Initialization

Ensure you have an environment configuration file. If no file is specified, the default `.env` file will be used.

```dart
import 'package:dedecube_environment/dedecube_environment.dart';
import 'package:get_it/get_it.dart';

final environment = Environment();
await environment.initialize();

GetIt.I.registerSingleton<Environment>(environment);

```

### Retrieving Environment Variables

String

```dart
import 'package:dedecube_environment/dedecube_environment.dart';

String? value = environment.tryGetString('MY_STRING_KEY');
String valueWithDefault = environment.getString('MY_STRING_KEY', 'default_value');

```

Integer

```dart
import 'package:dedecube_environment/dedecube_environment.dart';

int? intValue = environment.tryGetInt('MY_INT_KEY');
int intValueWithDefault = environment.getInt('MY_INT_KEY', 42);

```

Double

```dart
import 'package:dedecube_environment/dedecube_environment.dart';

double? doubleValue = environment.tryGetDouble('MY_DOUBLE_KEY');
double doubleValueWithDefault = environment.getDouble('MY_DOUBLE_KEY', 3.14);

```

Boolean

```dart
import 'package:dedecube_environment/dedecube_environment.dart';

bool? boolValue = environment.tryGetBool('MY_BOOL_KEY');
bool boolValueWithDefault = environment.getBool('MY_BOOL_KEY', true);

```

## License

Dedecube Environment is released under the [MIT License](LICENSE).
