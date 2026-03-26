// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../repository_registration_utils.dart';

class RepositoryRegistrationLifecycleEnforcedRule extends DartLintRule {
  RepositoryRegistrationLifecycleEnforcedRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'repository_registration_lifecycle_enforced',
            problemMessage:
                'Repository registration must use singleton lifecycle, not factory lifecycle.',
            correctionMessage:
                'Treatments: use registerLazySingleton/registerSingleton (or module_settings singleton wrappers) for repositories.',
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

    context.registry.addMethodInvocation((node) {
      if (!isRepositoryFactoryLifecycleInvocation(node)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }
}
