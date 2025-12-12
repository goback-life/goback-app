import 'package:dedecube_translator/src/data/services/translator_service.dart';
import 'package:dedecube_translator/src/domain/contracts/translator_repository_contract.dart';
import 'package:flutter/widgets.dart';

/// Implementation of [TranslatorRepositoryContract].
///
/// This repository delegates translation operations to the underlying
/// [TranslatorService].
class TranslatorRepository implements TranslatorRepositoryContract {
  /// Creates a [TranslatorRepository] with the given [TranslatorService].
  const TranslatorRepository({required this.translatorService});

  final TranslatorService translatorService;

  @override
  String? translate(
    String key, {
    BuildContext? context,
    Map<String, String>? arguments,
  }) {
    return translatorService.translate(
      key,
      context: context,
      arguments: arguments,
    );
  }

  @override
  Future<void> setLocale(
    Locale locale, {
    required bool reassemble,
    BuildContext? context,
  }) async {
    return await translatorService.setLocale(
      locale,
      reassemble: reassemble,
      context: context,
    );
  }
}
