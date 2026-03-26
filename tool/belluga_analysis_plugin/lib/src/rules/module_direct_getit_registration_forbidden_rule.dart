// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class ModuleDirectGetItRegistrationForbiddenRule extends DartLintRule {
  ModuleDirectGetItRegistrationForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'module_direct_getit_registration_forbidden',
            problemMessage:
                'ModuleContract classes cannot register dependencies via direct GetIt register APIs.',
            correctionMessage:
                'Treatments: replace direct GetIt.I.register* with ModuleContract lifecycle wrappers (registerLazySingleton/registerFactory/registerRouteResolver).',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isModularModuleFilePath(path)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (!isGetItRegistrationMethodInvocation(node)) {
        return;
      }

      final classNode = _enclosingClass(node);
      if (classNode == null || !_extendsModuleContract(classNode)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }

  ClassDeclaration? _enclosingClass(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  bool _extendsModuleContract(ClassDeclaration classNode) {
    final extendsClause = classNode.extendsClause;
    if (extendsClause == null) {
      return false;
    }

    final superTypeName =
        normalizeTypeName(extendsClause.superclass.toSource());
    return superTypeName == 'ModuleContract';
  }
}
