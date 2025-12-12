import 'dart:developer';

import 'package:dedecube_translator/src/data/configs/translator_config.dart';
import 'package:dedecube_translator/src/domain/contracts/translator_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_i18n/loaders/file_translation_loader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Extension on [TranslatorContract] to provide access to localization delegates.
extension TranslatorLocalizationsDelegatesExtension on TranslatorContract {
  /// Private list of global [LocalizationsDelegate]s.
  static const List<LocalizationsDelegate> _globalDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// Private list of custom [LocalizationsDelegate]s.
  List<LocalizationsDelegate> _customDelegates(TranslatorConfig config) => [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: config.path,
          ),
          missingTranslationHandler: (key, locale) {
            log(
              '--- Missing Key: $key, languageCode: ${locale?.languageCode}',
            );
          },
        ),
      ];

  /// Retrieves the combined list of [LocalizationsDelegate]s for localization.
  ///
  /// Combines both global and custom delegates to provide comprehensive localization support.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<LocalizationsDelegate> delegates = translator.localizationsDelegates;
  /// ```
  List<LocalizationsDelegate> get localizationsDelegates =>
      [..._globalDelegates, ..._customDelegates(config)];
}
