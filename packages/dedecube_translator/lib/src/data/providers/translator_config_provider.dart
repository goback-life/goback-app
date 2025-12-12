import 'package:dedecube_translator/src/data/configs/translator_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'translator_config_provider.g.dart';

/// A [Provider] for [TranslatorConfig].
@Riverpod(keepAlive: true)
class TranslatorConfigNotifier extends _$TranslatorConfigNotifier {
  TranslatorConfigNotifier();

  @override
  TranslatorConfig build() {
    return TranslatorConfig();
  }

  set translatorConfig(TranslatorConfig newConfig) {
    state = newConfig;
  }
}
