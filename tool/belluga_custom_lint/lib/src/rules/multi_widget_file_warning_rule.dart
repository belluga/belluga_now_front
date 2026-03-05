// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class MultiWidgetFileWarningRule extends DartLintRule {
  MultiWidgetFileWarningRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'multi_widget_file_warning',
            problemMessage:
                'Screen files should avoid declaring multiple widget classes.',
            correctionMessage:
                'Treatments: keep one screen widget per screen file; move extra widgets to dedicated widget files.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!path.contains('/lib/presentation/') ||
        !path.contains('/screens/') ||
        !path.endsWith('_screen.dart')) {
      return;
    }

    context.registry.addCompilationUnit((unit) {
      final widgetClasses = unit.declarations
          .whereType<ClassDeclaration>()
          .where(_isWidgetClass)
          .toList();

      if (widgetClasses.length <= 1) {
        return;
      }

      for (final classDeclaration in widgetClasses.skip(1)) {
        reporter.atNode(classDeclaration, code);
      }
    });
  }

  bool _isWidgetClass(ClassDeclaration node) {
    final name = node.name.lexeme;
    if (name.startsWith('_')) {
      return false;
    }

    final extendsClause = node.extendsClause;
    if (extendsClause == null) {
      return false;
    }

    final typeName = normalizeTypeName(extendsClause.superclass.toSource());
    if (typeName != 'StatelessWidget' && typeName != 'StatefulWidget') {
      return false;
    }

    return name.endsWith('Screen') || name.endsWith('Widget');
  }
}
