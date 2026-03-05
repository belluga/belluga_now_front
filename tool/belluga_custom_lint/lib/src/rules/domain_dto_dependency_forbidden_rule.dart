// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../dto_uri_utils.dart';
import '../path_utils.dart';

class DomainDtoDependencyForbiddenRule extends DartLintRule {
  DomainDtoDependencyForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'domain_dto_dependency_forbidden',
            problemMessage:
                'Domain layer cannot depend on DTO artifacts.',
            correctionMessage:
                'Treatments: keep DTO mapping in infrastructure; expose only domain models/contracts in domain layer.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isDomainFilePath(path)) {
      return;
    }

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) {
        return;
      }

      if (!isDtoUri(uri)) {
        return;
      }

      reporter.atNode(node.uri, code);
    });
  }
}
