// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class DtoMapperPassThroughForbiddenRule extends DartLintRule {
  DtoMapperPassThroughForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'dto_mapper_pass_through_forbidden',
            problemMessage:
                'Mapper methods converting DTO/primitives to domain are forbidden.',
            correctionMessage:
                'Treatments: remove mapper conversion methods and keep DTO->Domain conversion exclusively in DTO.toDomain().',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isDtoMapperFilePath(path) || isGeneratedFilePath(path)) {
      return;
    }

    context.registry.addMethodDeclaration((node) {
      if (!_returnsDomainPayload(node.returnType)) {
        return;
      }

      if (!_hasMapperLikeInput(node.parameters)) {
        return;
      }

      reporter.atNode(node, code);
    });

    context.registry.addFunctionDeclaration((node) {
      if (!_returnsDomainPayload(node.returnType)) {
        return;
      }

      if (!_hasMapperLikeInput(node.functionExpression.parameters)) {
        return;
      }

      reporter.atNode(node, code);
    });
  }

  bool _hasMapperLikeInput(FormalParameterList? parameters) {
    if (parameters == null) {
      return false;
    }

    for (final parameter in parameters.parameters) {
      final type = formalParameterType(parameter);
      if (containsDtoTypeAnnotation(type) ||
          containsForbiddenDomainPrimitiveType(type)) {
        return true;
      }
    }

    return false;
  }

  bool _returnsDomainPayload(TypeAnnotation? returnType) {
    if (!hasMeaningfulPayloadType(returnType)) {
      return false;
    }
    return !containsDtoTypeAnnotation(returnType);
  }
}
