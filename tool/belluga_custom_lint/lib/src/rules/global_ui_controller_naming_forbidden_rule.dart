// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class GlobalUiControllerNamingForbiddenRule extends DartLintRule {
  GlobalUiControllerNamingForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'global_ui_controller_naming_forbidden',
            problemMessage:
                'Global registrations cannot use UI controller naming (*Controller/*ControllerContract).',
            correctionMessage:
                'Treatments: reclassify as module-scoped UI controller or rename to a non-UI global type (for example, *Service/*Gate/*Coordinator).',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isAllowedGlobalRegistrationFilePath(path)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (!isGetItRegistrationMethodInvocation(node)) {
        return;
      }

      final registeredType = _registeredTypeName(node);
      if (!isControllerTypeName(registeredType)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }

  String? _registeredTypeName(MethodInvocation node) {
    final typeArgument = firstTypeArgumentName(node.typeArguments);
    if (typeArgument != null && typeArgument.isNotEmpty) {
      return typeArgument;
    }

    final arguments = node.argumentList.arguments;
    if (arguments.isEmpty) {
      return null;
    }

    return dartTypeName(arguments.first.staticType);
  }
}
