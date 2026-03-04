// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ScreenControllerResolutionPatternRequiredRule extends DartLintRule {
  ScreenControllerResolutionPatternRequiredRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'screen_controller_resolution_pattern_required',
            problemMessage:
                'Screen classes must resolve feature controllers via GetIt instead of receiving them via constructor.',
            correctionMessage:
                'Treatments: remove controller constructor params from screen classes; resolve controller at screen boundary via GetIt.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!path.contains('/lib/presentation/') || !path.contains('/screens/')) {
      return;
    }

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      if (!className.endsWith('Screen')) {
        return;
      }

      if (!_extendsWidget(node)) {
        return;
      }

      for (final member in node.members) {
        if (member is! ConstructorDeclaration) {
          continue;
        }

        for (final parameter in member.parameters.parameters) {
          final typeName = _formalParameterTypeName(parameter);
          if (!isControllerTypeName(typeName)) {
            continue;
          }

          reporter.atNode(parameter, code);
        }
      }
    });
  }

  bool _extendsWidget(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause == null) {
      return false;
    }

    final typeName = normalizeTypeName(extendsClause.superclass.toSource());
    return typeName == 'StatelessWidget' || typeName == 'StatefulWidget';
  }

  String? _formalParameterTypeName(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return _formalParameterTypeName(parameter.parameter);
    }

    if (parameter is SimpleFormalParameter) {
      return normalizeTypeName(parameter.type?.toSource() ?? '');
    }

    if (parameter is FieldFormalParameter) {
      final explicitType = normalizeTypeName(parameter.type?.toSource() ?? '');
      if (explicitType.isNotEmpty) {
        return explicitType;
      }

      final fieldName = parameter.name.lexeme;
      if (fieldName.toLowerCase().contains('controller')) {
        return 'Controller';
      }

      return '';
    }

    return null;
  }
}
