// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class RepositoryRawTransportTypingForbiddenRule extends DartLintRule {
  RepositoryRawTransportTypingForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'repository_raw_transport_typing_forbidden',
            problemMessage:
                'Repositories cannot declare raw transport typing (dynamic/Map<String, dynamic>).',
            correctionMessage:
                'Treatments: keep raw payload typing/parsing inside DAO adapters; repositories must consume typed DTOs/services and return domain/projection objects.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isRepositoryFilePath(path) || isGeneratedFilePath(path)) {
      return;
    }

    context.registry.addFieldDeclaration((node) {
      _reportTypeIfForbidden(node.fields.type, reporter);
    });

    context.registry.addVariableDeclaration((node) {
      final parent = node.parent;
      if (parent is! VariableDeclarationList) {
        return;
      }

      _reportTypeIfForbidden(parent.type, reporter);
    });

    context.registry.addMethodDeclaration((node) {
      _reportTypeIfForbidden(node.returnType, reporter);
      _reportForbiddenParameterTypes(node.parameters, reporter);
    });

    context.registry.addFunctionDeclaration((node) {
      _reportTypeIfForbidden(node.returnType, reporter);
      _reportForbiddenParameterTypes(
        node.functionExpression.parameters,
        reporter,
      );
    });

    context.registry.addInstanceCreationExpression((node) {
      _reportTypeIfForbidden(node.constructorName.type, reporter);
    });
  }

  void _reportForbiddenParameterTypes(
    FormalParameterList? parameters,
    ErrorReporter reporter,
  ) {
    if (parameters == null) {
      return;
    }

    for (final parameter in parameters.parameters) {
      final type = _parameterType(parameter);
      _reportTypeIfForbidden(type, reporter);
    }
  }

  void _reportTypeIfForbidden(TypeAnnotation? type, ErrorReporter reporter) {
    if (!containsForbiddenRepositoryRawTransportType(type) || type == null) {
      return;
    }

    reporter.atNode(type, code);
  }

  TypeAnnotation? _parameterType(FormalParameter parameter) {
    final normalized =
        parameter is DefaultFormalParameter ? parameter.parameter : parameter;

    if (normalized is SimpleFormalParameter) {
      return normalized.type;
    }

    if (normalized is SuperFormalParameter) {
      return normalized.type;
    }

    if (normalized is FieldFormalParameter) {
      return normalized.type;
    }

    if (normalized is FunctionTypedFormalParameter) {
      return normalized.returnType;
    }

    return null;
  }
}
