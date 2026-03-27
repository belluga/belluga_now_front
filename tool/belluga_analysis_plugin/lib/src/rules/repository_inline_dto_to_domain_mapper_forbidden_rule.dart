// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class RepositoryInlineDtoToDomainMapperForbiddenRule extends DartLintRule {
  RepositoryInlineDtoToDomainMapperForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'repository_inline_dto_to_domain_mapper_forbidden',
            problemMessage:
                'Repositories cannot own inline DTO-to-domain mapper methods.',
            correctionMessage:
                'Treatments: move DTO-to-domain conversion into dedicated mapper files under lib/infrastructure/dal/dto/mappers and let repositories delegate to them.',
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

    context.registry.addMethodDeclaration((node) {
      if (!_hasDtoParameters(node.parameters) ||
          !_returnsMappedValue(node.returnType)) {
        return;
      }

      reporter.atNode(node, code);
    });

    context.registry.addFunctionDeclaration((node) {
      if (!_hasDtoParameters(node.functionExpression.parameters) ||
          !_returnsMappedValue(node.returnType)) {
        return;
      }

      reporter.atNode(node, code);
    });
  }

  bool _hasDtoParameters(FormalParameterList? parameters) {
    if (parameters == null) {
      return false;
    }

    for (final parameter in parameters.parameters) {
      final type = _parameterType(parameter);
      if (containsDtoTypeAnnotation(type)) {
        return true;
      }
    }

    return false;
  }

  TypeAnnotation? _parameterType(FormalParameter parameter) {
    final normalized = parameter is DefaultFormalParameter
        ? parameter.parameter
        : parameter;

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

  bool _returnsMappedValue(TypeAnnotation? returnType) {
    if (!hasMeaningfulPayloadType(returnType)) {
      return false;
    }

    return !containsDtoTypeAnnotation(returnType);
  }
}
