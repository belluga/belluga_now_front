// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class DomainPrimitiveFieldForbiddenRule extends DartLintRule {
  DomainPrimitiveFieldForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'domain_primitive_field_forbidden',
          problemMessage:
              'Domain fields cannot use primitive transport-oriented types directly.',
          correctionMessage:
              'Domain parameters must be only domain-owned types, ValueObject<T>, or List/Set/Iterable whose element type is a domain-owned type or ValueObject<T>. Any other parameter type is forbidden. Types declared under domain/**/value_objects/** must extend ValueObject<T>. ValueObject<T> cannot use Map/List/Set/Iterable/Collection as T. Domain fields and collection/map return signatures must avoid primitive/transport types. For grouped data, create an auxiliary domain model composed by ValueObjects. Typedef aliases do not remediate primitive usage. Validation belongs inside ValueObjects.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isDomainFilePath(path) ||
        isDomainValueObjectFilePath(path) ||
        isGeneratedFilePath(path)) {
      return;
    }

    context.registry.addFieldDeclaration((node) {
      if (node.isStatic) {
        return;
      }

      if (!containsForbiddenDomainPrimitiveType(node.fields.type)) {
        return;
      }

      for (final variable in node.fields.variables) {
        reporter.atOffset(
          errorCode: code,
          offset: variable.name.offset,
          length: variable.name.length,
        );
      }
    });

    context.registry.addConstructorDeclaration((node) {
      _reportForbiddenParameterTypes(node.parameters, reporter);
    });

    context.registry.addMethodDeclaration((node) {
      if (node.isOperator && node.name.lexeme == '==') {
        return;
      }
      _reportForbiddenCollectionLikeReturnType(node.returnType, reporter);
      _reportForbiddenParameterTypes(node.parameters, reporter);
    });

    context.registry.addFunctionDeclaration((node) {
      _reportForbiddenCollectionLikeReturnType(node.returnType, reporter);
      _reportForbiddenParameterTypes(
        node.functionExpression.parameters,
        reporter,
      );
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
      final type = formalParameterType(parameter);
      if (type == null || isAllowedDomainParameterType(type)) {
        continue;
      }

      reporter.atOffset(
        errorCode: code,
        offset: type.offset,
        length: type.length,
      );
    }
  }

  void _reportForbiddenCollectionLikeReturnType(
    TypeAnnotation? returnType,
    ErrorReporter reporter,
  ) {
    if (returnType == null) {
      return;
    }

    if (!_isForbiddenDomainCollectionLikeType(returnType)) {
      return;
    }

    reporter.atOffset(
      errorCode: code,
      offset: returnType.offset,
      length: returnType.length,
    );
  }

  bool _isForbiddenDomainCollectionLikeType(TypeAnnotation type) {
    final typeName = topLevelTypeName(type);
    if (typeName == null) {
      return false;
    }

    if (typeName != 'Map' &&
        typeName != 'List' &&
        typeName != 'Set' &&
        typeName != 'Iterable') {
      return false;
    }

    return containsForbiddenDomainPrimitiveType(type);
  }
}
