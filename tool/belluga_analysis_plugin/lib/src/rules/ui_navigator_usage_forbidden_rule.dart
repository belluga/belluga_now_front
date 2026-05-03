// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

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
    if (!isNavigatorPolicyFilePath(path)) {
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
