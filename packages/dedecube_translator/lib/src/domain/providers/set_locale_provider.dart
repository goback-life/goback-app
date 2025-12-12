import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_translator/src/data/providers/translator_repository_provider.dart';
import 'package:dedecube_translator/src/domain/use_cases/set_locale_use_case.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_locale_provider.g.dart';

/// Sets the current locale in the application.
///
/// Creates an instance of [`SetLocaleUseCase`](lib/src/domain/use_cases/set_locale_use_case.dart)
/// and executes it to update the application's locale.
///
/// - [ref]: The provider reference.
/// - [locale]: The locale to set.
/// - [context]: The build context, if any.
///
/// Returns a `Future` that completes when the locale has been updated.
@Riverpod(keepAlive: false)
Future<void> setLocale(
  Ref ref,
  Locale locale, {
  required bool reassemble,
  BuildContext? context,
}) async {
  final setLocaleUseCase = SetLocaleUseCase(
    repository: ref.watch(translatorRepositoryProvider),
    locale: locale,
    reassemble: reassemble,
    context: context,
  );

  return await setLocaleUseCase.execute();
}
