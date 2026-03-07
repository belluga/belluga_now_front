// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';

class UiNavigatorUsageForbiddenRule extends DartLintRule {
  UiNavigatorUsageForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_navigator_usage_forbidden',
            problemMessage:
                'Direct Navigator usage is forbidden in UI files under router policy.',
            correctionMessage:
                'Treatments: replace Navigator.* calls with project router abstractions (for example, context.router).',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isUiPresentationFilePath(path)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      final targetSource = node.target?.toSource();
      if (targetSource == null) {
        return;
      }

      if (targetSource == 'Navigator' || targetSource.startsWith('Navigator.')) {
        reporter.atNode(node.methodName, code);
      }
    });
  }
}
