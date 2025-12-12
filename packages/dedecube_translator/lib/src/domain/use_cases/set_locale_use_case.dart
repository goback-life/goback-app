import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_translator/src/domain/contracts/translator_repository_contract.dart';
import 'package:flutter/widgets.dart';

/// [SetLocaleUseCase] handles updating the application's current locale based on localization configurations.
class SetLocaleUseCase implements UseCaseContract<void> {
  /// Creates an instance of [SetLocaleUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`TranslatorRepositoryContract`](lib/src/domain/contracts/translator_repository_contract.dart) used to perform locale updates.
  /// - [locale]: The new [Locale] to set as the current locale.
  /// - [reassemble]: A flag indicating whether the application should reassemble after updating the locale.
  /// - [context]: The build context, if any.
  SetLocaleUseCase({
    required this.repository,
    required this.locale,
    required this.reassemble,
    this.context,
  });

  /// The repository responsible for handling translator operations.
  final TranslatorRepositoryContract repository;

  /// The locale to set as the current locale.
  final Locale locale;

  /// A flag indicating whether the application should reassemble after updating the locale.
  final bool reassemble;

  /// The optional build context, if required.
  final BuildContext? context;

  /// Executes the use case to update the current locale.
  ///
  /// Delegates the locale update task to the [repository]'s [`setLocale`](lib/src/domain/contracts/translator_repository_contract.dart) method.
  @override
  Future<void> execute() async {
    return await repository.setLocale(
      locale,
      reassemble: reassemble,
      context: context,
    );
  }
}
