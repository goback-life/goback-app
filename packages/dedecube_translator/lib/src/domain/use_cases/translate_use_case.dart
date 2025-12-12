import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_translator/src/domain/contracts/translator_repository_contract.dart';
import 'package:flutter/widgets.dart';

/// [TranslateUseCase] handles the translation of strings based on localization configurations.
class TranslateUseCase implements UseCaseContract<void> {
  /// Creates an instance of [TranslateUseCase] with the required dependencies.
  ///
  /// - [repository]: An instance of [`TranslatorRepositoryContract`](lib/src/domain/contracts/translator_repository_contract.dart) used to perform the translation.
  /// - [key]: The key to translate.
  /// - [context]: The build context, if any.
  /// - [arguments]: Any arguments for the translation.
  TranslateUseCase({
    required this.repository,
    required this.key,
    this.context,
    this.arguments,
  });

  /// The repository responsible for translation operations.
  final TranslatorRepositoryContract repository;

  /// The key for the translation.
  final String key;

  /// The build context, if any.
  final BuildContext? context;

  /// Any arguments for the translation.
  final Map<String, String>? arguments;

  /// Executes the use case to perform the translation.
  ///
  /// Delegates the translation task to the [repository]'s [`translate`](lib/src/domain/contracts/translator_repository_contract.dart) method.
  @override
  String? execute() {
    return repository.translate(
      key,
      context: context,
      arguments: arguments,
    );
  }
}
