import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dedecube_custom_lints/src/utilities/json_loader.dart';
import 'package:yaml/yaml.dart';

class TranslationKeyExists extends DartLintRule {
  /// Constructor for the TranslationKeyExists lint rule.
  ///
  /// Takes a [CustomLintConfigs] parameter and an optional [code] parameter.
  /// Initializes the translation file paths based on the provided configuration.
  ///
  /// If a YAML configuration is provided in the format:
  /// ```yaml
  /// rules:
  ///   translation_key_exists:
  ///     locales:
  ///       en: ['path/to/en.json']
  ///       it: ['path/to/it.json']
  /// ```
  /// It will use those paths. Otherwise, defaults to:
  /// - 'assets/translation/en.json' for English
  /// - 'assets/translation/it.json' for Italian
  ///
  /// @param configs The custom lint configurations
  /// @param code Optional code parameter with default value of _code
  TranslationKeyExists(CustomLintConfigs configs, {super.code = _code}) {
    final yamlMap = configs.rules[_code.name]?.json['locales'] as YamlMap?;

    if (yamlMap != null) {
      _jsonFiles = yamlMap.map((key, value) {
        return MapEntry(key.toString(), List<String>.from(value));
      });
    } else {
      _jsonFiles = {
        'en': ['assets/translations/en.json'],
        'it': ['assets/translations/it.json'],
      };
    }
  }

  late final Map<String, List<String>> _jsonFiles;

  static const _code = LintCode(
    name: 'translation_key_does_exist',
    problemMessage: 'Translation key does not exist in the {0} json file.',
  );

  /// Runs the custom lint rule to check if translation keys exist in JSON files.
  ///
  /// This method is called for each source file being analyzed. It registers a callback
  /// that gets invoked for every method invocation in the source code.
  ///
  /// Specifically checks for calls to `context.translate()` and verifies if the
  /// translation key exists in the JSON translation files.
  ///
  /// Parameters:
  /// - [resolver] - The resolver providing compilation and analysis information
  /// - [reporter] - Used to report lint errors found during analysis
  /// - [context] - Provides access to the source code being analyzed
  ///
  /// The method searches for the project directory and checks translation keys
  /// against all registered JSON translation files.
  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;

      if (methodName == 'translate' && node.target.toString() == 'translator') {
        final projectPath =
            findProjectDirectory(Directory.fromUri(Uri.file(resolver.path)));

        for (final entry in _jsonFiles.entries) {
          _checkTranslationKeyExists(
            entry.key,
            entry.value,
            node,
            projectPath,
            reporter,
          );
        }
      }
    });
  }

  /// Validates if a translation key exists within the translation files.
  ///
  /// This method checks whether a given translation key is present in the defined
  /// translation files, helping to prevent usage of non-existent translation keys
  /// in the codebase.
  ///
  /// Returns a list of [Lint] issues if any translation key violations are found.
  _checkTranslationKeyExists(
    String locale,
    List<String> jsonFiles,
    MethodInvocation node,
    Directory projectPath,
    ErrorReporter reporter,
  ) {
    final jsonLoader = JsonLoader(
      jsonFiles.map((file) {
        return '${projectPath.path}/$file';
      }).toList(),
    );
    final translationKeys = jsonLoader.loadAllKeys();

    final arguments = node.argumentList.arguments;

    if (arguments.isNotEmpty && arguments[0] is StringLiteral) {
      final key = arguments[0] as StringLiteral;

      if (!jsonLoader.containsKey(translationKeys, key.stringValue!)) {
        reporter.atNode(node, code, arguments: [locale]);
      }
    }
  }
}
