// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class DomainJsonFactoryForbiddenRule extends DartLintRule {
  DomainJsonFactoryForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'domain_json_factory_forbidden',
            problemMessage:
                'Domain files cannot declare fromJson/fromMap factories.',
            correctionMessage:
                'Treatments: move JSON parsing to DAO/DTO layers and expose domain construction through infrastructure mappers or fromPrimitives.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isDomainFilePath(path) || isGeneratedFilePath(path)) {
      return;
    }

    context.registry.addConstructorDeclaration((node) {
      if (node.factoryKeyword == null) {
        return;
      }

      final name = node.name?.lexeme;
      if (name != 'fromJson' && name != 'fromMap') {
        return;
      }

      reporter.atNode(node, code);
    });
  }
}
