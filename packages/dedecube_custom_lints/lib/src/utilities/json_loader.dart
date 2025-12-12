import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A utility class that loads and watches JSON files for changes.
///
/// This class provides functionality to:
/// * Load multiple JSON files and combine their contents
/// * Watch files for changes and notify listeners
/// * Automatically reload files when changes are detected
///
/// Example usage:
/// ```dart
/// final loader = JsonLoader(['config.json', 'settings.json']);
/// loader.startWatching();
/// loader.onChange.listen((_) {
///   final data = loader.loadAllFiles();
///   print('Files changed: $data');
/// });
/// ```
class JsonLoader {
  /// Creates a new [JsonLoader] instance.
  ///
  /// [jsonFiles] is a list of file paths to JSON files that should be loaded
  /// and watched for changes.
  JsonLoader(this.jsonFiles);

  /// The list of JSON file paths to load and watch.
  final List<String> jsonFiles;

  /// Controller for the change notification stream.
  final StreamController<void> _onChangeController = StreamController<void>();

  /// Stream that emits events whenever any of the watched JSON files change.
  ///
  /// Listen to this stream to be notified when files need to be reloaded.
  Stream<void> get onChange => _onChangeController.stream;

  /// Loads a single JSON file and returns its contents as a Map.
  ///
  /// Returns an empty Map if the file doesn't exist.
  /// Throws [FormatException] if the file contains invalid JSON.
  ///
  /// [filePath] is the path to the JSON file to load.
  Map<String, dynamic> _loadJsonFile(String filePath) {
    final file = File(filePath);

    if (!file.existsSync()) {
      return {};
    }

    final contents = file.readAsStringSync();

    return jsonDecode(contents);
  }

  /// Loads and merges all keys from multiple JSON files into a single map.
  ///
  /// This method iterates through all JSON files in [jsonFiles], loads each file's
  /// content, and combines them into a single map. If multiple files contain the
  /// same keys, later files will override values from earlier files.
  ///
  /// Returns a [Map<String, dynamic>] containing all merged key-value pairs from
  /// all JSON files.
  Map<String, dynamic> loadAllKeys() {
    final Map<String, dynamic> allKeys = {};

    for (final filePath in jsonFiles) {
      final absolutePath = _resolvePath(filePath);
      final jsonMap = _loadJsonFile(absolutePath);
      allKeys.addAll(jsonMap);
    }

    return allKeys;
  }

  /// Resolves the provided relative path to its absolute path.
  ///
  /// Takes a [relativePath] as a String and converts it to an absolute path using
  /// the current working directory as the base.
  ///
  /// Returns a [String] containing the absolute path.
  String _resolvePath(String relativePath) {
    return File(relativePath).absolute.path;
  }

  /// Checks if a given key exists within a JSON map.
  ///
  /// Takes a [jsonMap] representing the JSON data structure and a [key] string to search for.
  /// Returns true if the key exists in the map, false otherwise.
  bool containsKey(Map<String, dynamic> jsonMap, String key) {
    final parts = key.split('.');
    var current = jsonMap;
    for (final part in parts) {
      if (current.containsKey(part)) {
        final value = current[part];
        if (value is Map<String, dynamic>) {
          current = value;
        } else if (value is String && part == parts.last) {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    }
    return true;
  }
}
