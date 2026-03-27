// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ModuleScopedControllerDisposeForbiddenRule extends DartLintRule {
  ModuleScopedControllerDisposeForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'module_scoped_controller_dispose_forbidden',
            problemMessage:
                'Widgets/screens must not dispose module-scoped controllers.',
            correctionMessage:
                'Treatments: remove manual dispose/onDispose on feature controllers in UI; rely on ModuleScope teardown.',
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
      final methodName = node.methodName.name;
      if (methodName != 'dispose' && methodName != 'onDispose') {
        return;
      }

      final target = node.realTarget;
      final targetSource = target?.toSource() ?? '';
      final targetTypeName = dartTypeName(target?.staticType);

      if (isUiControllerTypeName(targetTypeName)) {
        return;
      }

      final controllerByType = isControllerTypeName(targetTypeName);
      final controllerByName = targetSource.toLowerCase().contains('controller');

      if (!controllerByType && !controllerByName) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }
}
