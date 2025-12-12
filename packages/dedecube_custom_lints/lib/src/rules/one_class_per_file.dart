import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class OneClassPerFile extends DartLintRule {
  const OneClassPerFile() : super(code: _code);

  static const _code = LintCode(
    name: 'one_class_per_file',
    problemMessage: 'Only one class allowed per file',
  );

  /// Executes the lint rule analysis to check if there is more than one class defined in a file.
  ///
  /// This method is the main entry point for the lint rule and performs the analysis
  /// of the source code to detect multiple class declarations within a single file.
  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    int classCount = 0;

    context.registry.addClassDeclaration((node) {
      final element = node.declaredElement;

      if (element == null) {
        return;
      }

      classCount++;

      if (classCount > 1) {
        reporter.atElement(element, code);
      }
    });
  }
}
