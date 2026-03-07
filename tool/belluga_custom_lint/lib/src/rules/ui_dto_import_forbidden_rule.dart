// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../dto_uri_utils.dart';
import '../path_utils.dart';

class UiDtoImportForbiddenRule extends DartLintRule {
  UiDtoImportForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_dto_import_forbidden',
            problemMessage:
                'Presentation layer cannot import DTO artifacts directly.',
            correctionMessage:
                'Treatments: replace DTO references with domain/projection models in UI; keep DTO mapping in infrastructure.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isPresentationFilePath(path)) {
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
