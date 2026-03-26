// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ControllerBuildContextDependencyForbiddenRule extends DartLintRule {
  ControllerBuildContextDependencyForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'controller_buildcontext_dependency_forbidden',
            problemMessage:
                'Controllers must not depend on BuildContext in fields, params, or APIs.',
            correctionMessage:
                'Treatments: remove BuildContext from controller APIs/fields; move context-bound behavior to UI/router layer.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isPresentationControllerFilePath(path)) {
      return;
    }

    context.registry.addNamedType((node) {
      final typeName = normalizeTypeName(node.toSource());
      if (typeName != 'BuildContext') {
        return;
      }

      reporter.atNode(node, code);
    });
  }
}
