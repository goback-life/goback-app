import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_translator/src/data/providers/translator_repository_provider.dart';
import 'package:dedecube_translator/src/domain/use_cases/translate_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'translate_provider.g.dart';

/// Translates a given key into the localized string.
///
/// Creates an instance of [`TranslateUseCase`](lib/src/domain/use_cases/translate_use_case.dart)
/// and executes it to obtain the translated string.
///
/// - [ref]: The provider reference.
/// - [key]: The key to translate.
/// - [context]: The build context, if any.
/// - [arguments]: Any arguments for the translation.
///
/// Returns the localized string associated with [key], or `null` if translation fails.
@Riverpod(keepAlive: false)
String? translate(
  Ref ref,
  String key, {
  BuildContext? context,
  Map<String, String>? arguments,
}) {
  final translateUseCase = TranslateUseCase(
    repository: ref.watch(translatorRepositoryProvider),
    key: key,
    context: context,
    arguments: arguments,
  );

  return translateUseCase.execute();
}
