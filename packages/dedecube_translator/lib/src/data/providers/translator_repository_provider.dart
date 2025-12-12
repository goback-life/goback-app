import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_translator/src/data/providers/translator_service_provider.dart';
import 'package:dedecube_translator/src/data/repositories/translator_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'translator_repository_provider.g.dart';

/// A [Provider] for [TranslatorRepository].
@Riverpod(keepAlive: true)
TranslatorRepository translatorRepository(
  Ref ref,
) {
  return TranslatorRepository(
    translatorService: ref.watch(translatorServiceProvider),
  );
}
