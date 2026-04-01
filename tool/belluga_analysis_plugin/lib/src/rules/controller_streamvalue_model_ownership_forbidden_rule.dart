// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ControllerStreamValueModelOwnershipForbiddenRule extends DartLintRule {
  ControllerStreamValueModelOwnershipForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'controller_streamvalue_model_ownership_forbidden',
            problemMessage:
                'Controller must not own StreamValue whose payload is a *Model type.',
            correctionMessage:
                'Treatments: move canonical model stream ownership to repository and expose it via controller delegation getter.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isPresentationControllerFilePath(path)) {
      return;
    }

    context.registry.addVariableDeclaration((node) {
      if (node.thisOrAncestorOfType<FieldDeclaration>() == null) {
        return;
      }

      final creation = _streamValueConstruction(node.initializer);
      if (creation == null) {
        return;
      }

      final declarationType = (node.parent is VariableDeclarationList)
          ? (node.parent as VariableDeclarationList).type
          : null;
      if (!_payloadContainsModelType(
        declaredType: declarationType,
        createdTypeArguments: creation.typeArguments,
      )) {
        return;
      }

      reporter.atNode(creation.reportNode, code);
    });

    context.registry.addAssignmentExpression((node) {
      if (node.operator.type != TokenType.EQ) {
        return;
      }

      final creation = _streamValueConstruction(node.rightHandSide);
      if (creation == null) {
        return;
      }

      if (!_payloadContainsModelType(
        staticType: node.leftHandSide.staticType,
        createdTypeArguments: creation.typeArguments,
      )) {
        return;
      }

      reporter.atNode(creation.reportNode, code);
    });
  }

  _StreamValueConstruction? _streamValueConstruction(Expression? expression) {
    if (expression is InstanceCreationExpression) {
      final typeName =
          normalizeTypeName(expression.constructorName.type.toSource());
      if (typeName != 'StreamValue') {
        return null;
      }

      return _StreamValueConstruction(
        reportNode: expression.constructorName.type,
        typeArguments: expression.constructorName.type.typeArguments,
      );
    }

    if (expression is MethodInvocation && expression.target == null) {
      final methodName = expression.methodName.name;
      if (methodName != 'StreamValue') {
        return null;
      }

      return _StreamValueConstruction(
        reportNode: expression.methodName,
        typeArguments: expression.typeArguments,
      );
    }

    return null;
  }

  bool _payloadContainsModelType({
    TypeAnnotation? declaredType,
    DartType? staticType,
    TypeArgumentList? createdTypeArguments,
  }) {
    if (_containsModelPayloadFromDeclaredType(declaredType)) {
      return true;
    }

    if (_containsModelPayloadFromStaticType(staticType)) {
      return true;
    }

    return _containsModelPayloadFromTypeArguments(createdTypeArguments);
  }

  bool _containsModelPayloadFromDeclaredType(TypeAnnotation? declaredType) {
    if (declaredType is! NamedType) {
      return false;
    }

    if (normalizeTypeName(declaredType.toSource()) != 'StreamValue') {
      return false;
    }

    final typeArguments = declaredType.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.isEmpty) {
      return false;
    }

    return typeArguments.any(_containsModelTypeAnnotation);
  }

  bool _containsModelPayloadFromStaticType(DartType? type) {
    if (type is! InterfaceType) {
      return false;
    }

    if (normalizeTypeName(type.getDisplayString()) != 'StreamValue') {
      return false;
    }

    if (type.typeArguments.isEmpty) {
      return false;
    }

    return type.typeArguments.any(_containsModelDartType);
  }

  bool _containsModelPayloadFromTypeArguments(
    TypeArgumentList? typeArguments,
  ) {
    final arguments = typeArguments?.arguments;
    if (arguments == null || arguments.isEmpty) {
      return false;
    }

    return arguments.any(_containsModelTypeAnnotation);
  }

  bool _containsModelTypeAnnotation(TypeAnnotation annotation) {
    if (annotation is! NamedType) {
      return false;
    }

    final typeName = topLevelTypeName(annotation);
    if (typeName == null || typeName.isEmpty) {
      return false;
    }

    if (typeName.endsWith('Model')) {
      return true;
    }

    final arguments = annotation.typeArguments?.arguments;
    if (arguments == null || arguments.isEmpty) {
      return false;
    }

    return arguments.any(_containsModelTypeAnnotation);
  }

  bool _containsModelDartType(DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    final typeName = normalizeTypeName(type.getDisplayString());
    if (typeName.endsWith('Model')) {
      return true;
    }

    if (type.typeArguments.isEmpty) {
      return false;
    }

    return type.typeArguments.any(_containsModelDartType);
  }
}

class _StreamValueConstruction {
  const _StreamValueConstruction({
    required this.reportNode,
    required this.typeArguments,
  });

  final AstNode reportNode;
  final TypeArgumentList? typeArguments;
}
