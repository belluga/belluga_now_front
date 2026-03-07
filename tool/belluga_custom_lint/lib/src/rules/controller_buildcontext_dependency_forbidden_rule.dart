// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

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
