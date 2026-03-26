// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class IntegrationAnonymousAuthIdentifiedLoginForbiddenRule
    extends DartLintRule {
  IntegrationAnonymousAuthIdentifiedLoginForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'integration_anonymous_auth_identified_login_forbidden',
            problemMessage:
                'Anonymous-only integration tests must not use identified auth fallback.',
            correctionMessage:
                'Treatments: keep anonymous bootstrap only; remove login/sign-up fallback calls in this test.',
          ),
        );

  static const _markerName = 'kAnonymousAuthOnlyContract';
  static const _forbiddenMethods = {
    'loginWithEmailPassword',
    'signUpWithEmailPassword',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!_isIntegrationTestPath(path) || isGeneratedFilePath(path)) {
      return;
    }

    var anonymousOnlyEnabled = false;

    context.registry.addCompilationUnit((unit) {
      anonymousOnlyEnabled = _hasAnonymousOnlyMarker(unit);
    });

    context.registry.addMethodInvocation((node) {
      if (!anonymousOnlyEnabled) {
        return;
      }

      if (!_forbiddenMethods.contains(node.methodName.name)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }

  bool _isIntegrationTestPath(String path) {
    return path.contains('/integration_test/') ||
        path.startsWith('integration_test/');
  }

  bool _hasAnonymousOnlyMarker(CompilationUnit unit) {
    for (final declaration in unit.declarations) {
      if (declaration is! TopLevelVariableDeclaration) {
        continue;
      }

      final list = declaration.variables;
      if (!list.isConst) {
        continue;
      }

      for (final variable in list.variables) {
        if (variable.name.lexeme != _markerName) {
          continue;
        }
        final initializer = variable.initializer;
        if (initializer is BooleanLiteral && initializer.value) {
          return true;
        }
      }
    }

    return false;
  }
}
