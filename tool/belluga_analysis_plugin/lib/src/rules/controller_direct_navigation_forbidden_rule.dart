// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class ControllerDirectNavigationForbiddenRule extends DartLintRule {
  ControllerDirectNavigationForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'controller_direct_navigation_forbidden',
            problemMessage:
                'Controllers must not perform direct navigation calls.',
            correctionMessage:
                'Treatments: emit navigation intents/state in controller; execute navigation in UI/router guards.',
          ),
        );

  static const _routerMethodNames = {
    'push',
    'pop',
    'replace',
    'replaceAll',
    'navigate',
    'maybePop',
    'popUntil',
    'popUntilRoot',
  };

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
      final targetSource = node.target?.toSource();
      final methodName = node.methodName.name;

      if (targetSource != null) {
        final normalizedTarget = targetSource.toLowerCase();

        if (targetSource == 'Navigator' || targetSource.startsWith('Navigator.')) {
          reporter.atNode(node.methodName, code);
          return;
        }

        final looksLikeRouterCall =
            normalizedTarget.contains('router') && _routerMethodNames.contains(methodName);
        if (looksLikeRouterCall) {
          reporter.atNode(node.methodName, code);
        }
      }
    });
  }
}
