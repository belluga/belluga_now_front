// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../streamvalue_target_utils.dart';

class ControllerDelegatedStreamValueWriteForbiddenRule extends DartLintRule {
  ControllerDelegatedStreamValueWriteForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'controller_delegated_streamvalue_write_forbidden',
          problemMessage:
              'Controller must not mutate delegated StreamValue from repository/service contracts.',
          correctionMessage:
              'Treatments: treat delegated repository/service StreamValue as read-only; when canonical mutation is needed, route it through repository getter/setter APIs, otherwise use a controller-owned StreamValue for local screen-stage state.',
        ),
      );

  static const _forbiddenMethods = <String>{'addValue', 'addError'};

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
      if (!_forbiddenMethods.contains(node.methodName.name)) {
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
