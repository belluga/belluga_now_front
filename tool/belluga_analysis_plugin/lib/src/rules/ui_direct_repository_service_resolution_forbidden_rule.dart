// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class UiDirectRepositoryServiceResolutionForbiddenRule extends DartLintRule {
  UiDirectRepositoryServiceResolutionForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_direct_repository_service_resolution_forbidden',
            problemMessage:
                'UI files cannot resolve repository/service/DAO/DTO/backend types directly.',
            correctionMessage:
                'Treatments: replace repository/service resolution in UI with feature-controller API calls.',
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
      if (!isDataSourceTypeName(typeName)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });

    context.registry.addFunctionExpressionInvocation((node) {
      if (!isGetItCallableInvocation(node)) {
        return;
      }

      final typeName = firstTypeArgumentName(node.typeArguments);
      if (!isDataSourceTypeName(typeName)) {
        return;
      }

      reporter.atNode(node.function, code);
    });
  }
}
