// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../streamvalue_target_utils.dart';

class ControllerDelegatedStreamValueDisposeForbiddenRule extends DartLintRule {
  ControllerDelegatedStreamValueDisposeForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'controller_delegated_streamvalue_dispose_forbidden',
          problemMessage:
              'Controller must not dispose delegated StreamValue from repository/service contracts.',
          correctionMessage:
              'Treatments: dispose only controller-owned StreamValue fields; keep delegated repository/service streams alive.',
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

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'dispose') {
        return;
      }

      final target = node.realTarget;
      if (target == null) {
        return;
      }

      if (isDelegatedStreamTarget(target)) {
        reporter.atNode(node.methodName, code);
      }
    });
  }
}
