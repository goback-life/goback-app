import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidStringLiteralsInsideTextWidget extends DartLintRule {
  const AvoidStringLiteralsInsideTextWidget() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_string_literals_inside_text_widget',
    problemMessage:
        'Avoid using string literals inside Text or StyledText widgets. Use context.translate instead.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry
        .addInstanceCreationExpression((InstanceCreationExpression node) {
      final constructorName = node.constructorName.type.name2.lexeme;

      if (constructorName == 'Text') {
        final firstArgument = node.argumentList.arguments.first;
        if (firstArgument is StringLiteral) {
          reporter.atNode(firstArgument, code);
        }
      } else if (constructorName == 'StyledText') {
        for (final argument in node.argumentList.arguments) {
          if (argument is NamedExpression &&
              argument.name.label.name == 'text') {
            final expression = argument.expression;
            if (expression is StringLiteral) {
              reporter.atNode(expression, code);
            }
          }
        }
      }
    });
  }
}
