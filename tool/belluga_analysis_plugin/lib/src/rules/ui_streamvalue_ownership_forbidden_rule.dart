// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class UiStreamValueOwnershipForbiddenRule extends DartLintRule {
  UiStreamValueOwnershipForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_streamvalue_ownership_forbidden',
            problemMessage:
                'UI files must not own StreamValue/StreamController instances.',
            correctionMessage:
                'Treatments: move stream ownership to feature controller and expose read-only stream/value to UI.',
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

    context.registry.addVariableDeclaration((node) {
      final initializer = node.initializer;
      if (initializer is! InstanceCreationExpression) {
        return;
      }

      final typeName = normalizeTypeName(
        initializer.constructorName.type.toSource(),
      );
      if (typeName != 'StreamValue' && typeName != 'StreamController') {
        return;
      }

      reporter.atNode(initializer.constructorName.type, code);
    });

    context.registry.addMethodInvocation((node) {
      if (node.target != null) {
        return;
      }

      final methodName = node.methodName.name;
      if (methodName != 'StreamValue' && methodName != 'StreamController') {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }
}
