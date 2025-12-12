import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_translator/src/data/providers/translator_config_provider.dart';
import 'package:dedecube_translator/src/data/services/translator_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'translator_service_provider.g.dart';

/// A provider to access the [TranslatorService].
@Riverpod(keepAlive: true)
TranslatorService translatorService(Ref ref) {
  return TranslatorService(
    ref,
    config: ref.watch(translatorConfigNotifierProvider),
  );
}
