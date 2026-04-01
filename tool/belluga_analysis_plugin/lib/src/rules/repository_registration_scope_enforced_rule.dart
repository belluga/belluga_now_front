// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../repository_registration_utils.dart';

class RepositoryRegistrationScopeEnforcedRule extends DartLintRule {
  RepositoryRegistrationScopeEnforcedRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'repository_registration_scope_enforced',
            problemMessage:
                'Repository registration is allowed only in module_settings.dart.',
            correctionMessage:
                'Treatments: move repository DI registration to lib/application/router/modular_app/module_settings.dart.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isLibFilePath(path) || isGeneratedFilePath(path)) {
      return;
    }

    if (isModuleSettingsFilePath(path)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (!isRepositoryRegistrationInvocation(node)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }
}
