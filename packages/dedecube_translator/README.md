
# Dedecube Translator

Dedecube Translator is a Flutter package designed to simplify and centralize application localization. It provides a flexible and intuitive API to handle multiple languages seamlessly, leveraging a clean and organized architecture.

## Installation

Add `dedecube_translator` to your dependencies in `pubspec.yaml`:

```yaml
dependencies:
  dedecube_translator:
    git:
      url: git@github.com:dedecube/dedecube-translator.git
      ref: v0.0.15
```

## How to Use

### Creating Translation Files

Translation files must be structured as JSON files within your assets directory. A typical file structure might look like this:

```
assets/i18n/
├── en.json
├── it.json
├── fr.json
```

**Example translation file (`en.json`):**

```json
{
  "welcome_message": "Welcome to Dedecube!",
  "logout": "Logout",
  "greeting": "Hello, {name}!"
}
```

### Usage

Retrieve translations easily from anywhere in your application:

```dart
final translatedText = translator.translate('welcome_message');
```

### Dynamic Placeholders

Your translation files can include dynamic placeholders:

```json
{
  "greeting": "Hello, {name}!"
}
```

Pass parameters dynamically when retrieving translations:

```dart
final greeting = translator.translate('greeting', params: {'name': 'Elena'});
// Output: Hello, Elena!
```

## License

Dedecube Translator is released under the [MIT License](LICENSE).
