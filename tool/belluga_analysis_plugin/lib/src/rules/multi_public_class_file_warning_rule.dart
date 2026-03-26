// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class MultiPublicClassFileWarningRule extends DartLintRule {
  MultiPublicClassFileWarningRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'multi_public_class_file_warning',
            problemMessage:
                'Files under lib/ should avoid declaring multiple public classes.',
            correctionMessage:
                'Treatments: keep one public class per file; move extra public classes to dedicated files or make local helpers private when they are file-scoped only.',
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

    context.registry.addCompilationUnit((unit) {
      final publicClasses = unit.declarations
          .whereType<ClassDeclaration>()
          .where((node) => !node.name.lexeme.startsWith('_'))
          .toList(growable: false);

      if (publicClasses.length <= 1) {
        return;
      }

      for (final classDeclaration in publicClasses.skip(1)) {
        reporter.atNode(classDeclaration, code);
      }
    });
  }
}
