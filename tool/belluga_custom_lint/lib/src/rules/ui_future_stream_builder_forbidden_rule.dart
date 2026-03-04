// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class UiFutureStreamBuilderForbiddenRule extends DartLintRule {
  UiFutureStreamBuilderForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_future_stream_builder_forbidden',
            problemMessage:
                'UI files must not use FutureBuilder/StreamBuilder in this architecture.',
            correctionMessage:
                'Treatments: replace FutureBuilder/StreamBuilder with controller-owned StreamValue + StreamValueBuilder.',
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

    context.registry.addNamedType((node) {
      final typeName = normalizeTypeName(node.toSource());
      if (typeName != 'FutureBuilder' && typeName != 'StreamBuilder') {
        return;
      }

      reporter.atNode(node, code);
    });
  }
}
