// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class UiGetItNonControllerForbiddenRule extends DartLintRule {
  UiGetItNonControllerForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_getit_non_controller_forbidden',
            problemMessage:
                'UI files may resolve only controller types via GetIt.',
            correctionMessage:
                'Treatments: resolve only feature controllers in UI; delegate all data/service access behind controller APIs.',
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
      if (!isGetItMethodInvocation(node)) {
        return;
      }

      final typeName = firstTypeArgumentName(node.typeArguments);

      if (isControllerTypeName(typeName) || isDataSourceTypeName(typeName)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });

    context.registry.addFunctionExpressionInvocation((node) {
      if (!isGetItCallableInvocation(node)) {
        return;
      }

      final typeName = firstTypeArgumentName(node.typeArguments);

      if (isControllerTypeName(typeName) || isDataSourceTypeName(typeName)) {
        return;
      }

      reporter.atNode(node.function, code);
    });
  }
}
