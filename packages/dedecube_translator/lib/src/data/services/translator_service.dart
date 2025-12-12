import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_translator/src/data/configs/translator_config.dart';
import 'package:dedecube_translator/src/data/exceptions/translator_context_not_found_exception.dart';
import 'package:dedecube_translator/src/domain/contracts/translator_service_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

/// Service responsible for handling translation operations.
///
/// Implements [TranslatorServiceContract] to provide methods for translating
/// strings based on localization configurations.
class TranslatorService implements TranslatorServiceContract {
  /// Creates a [TranslatorService] with the given [TranslatorConfig].
  TranslatorService(
    Ref ref, {
    required this.config,
  });

  final TranslatorConfig config;

  @override
  String? translate(
    String key, {
    BuildContext? context,
    Map<String, String>? arguments,
  }) {
    final effectiveContext = _getEffectiveContext(false, context);

    if (effectiveContext == null) {
      return null;
    }

    return FlutterI18n.translate(
      effectiveContext,
      key,
      translationParams: arguments,
    );
  }

  @override
  Future<void> setLocale(
    Locale locale, {
    required bool reassemble,
    BuildContext? context,
  }) async {
    final effectiveContext = _getEffectiveContext(reassemble, context);

    if (effectiveContext == null) {
      return;
    }

    await FlutterI18n.refresh(effectiveContext, locale);
  }

  BuildContext? _getEffectiveContext(bool reassemble, BuildContext? context) {
    final effectiveContext = context ?? config.navigatorKey?.currentContext;
    if (effectiveContext == null) {
      // This is a workaround if during hot reload the context is not available.
      if (reassemble) {
        return null;
      } else {
        throw TranslatorContextNotFoundException();
      }
    }

    return effectiveContext;
  }
}
