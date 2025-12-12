import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dedecube_custom_lints/src/rules/avoid_string_literals_inside_text_widget.dart';
import 'package:dedecube_custom_lints/src/rules/one_class_per_file.dart';
import 'package:dedecube_custom_lints/src/rules/translation_key_exists.dart';

/// A custom lint plugin implementation for Dedecube projects.
class _DedecubeCustomLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      const OneClassPerFile(),
      const AvoidStringLiteralsInsideTextWidget(),
      TranslationKeyExists(configs),
    ];
  }

  @override
  List<Assist> getAssists() => [];
}

/// This is the entrypoint.
///
/// Returns a [PluginBase] instance of [_DedecubeCustomLints] class, which
/// contains the custom lint rules.
PluginBase createPlugin() => _DedecubeCustomLints();
