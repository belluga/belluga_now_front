// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../streamvalue_target_utils.dart';
import '../type_utils.dart';

class ControllerDelegatedStreamValueSnapshotFieldForbiddenRule
    extends DartLintRule {
  ControllerDelegatedStreamValueSnapshotFieldForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'controller_delegated_streamvalue_snapshot_field_forbidden',
          problemMessage:
              'Controller must not mirror delegated repository/service StreamValue snapshots into mutable private collection fields.',
          correctionMessage:
              'Treatments: keep canonical cache in repository StreamValue and derive screen state directly or via controller-owned StreamValue.',
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

    context.registry.addAssignmentExpression((node) {
      if (node.operator.type != TokenType.EQ) {
        return;
      }

      final targetField = _resolvePrivateMutableField(node.leftHandSide);
      if (targetField == null) {
        return;
      }

      if (!_containsDomainCollectionPayload(targetField.typeAnnotation) &&
          !_containsDomainCollectionPayloadFromDartType(
            targetField.staticType,
          )) {
        return;
      }

      final functionBody = node.thisOrAncestorOfType<FunctionBody>();
      if (functionBody == null) {
        return;
      }

      final detector = _DelegatedSnapshotReadDetector(
        functionBody: functionBody,
      );
      if (!detector.contains(node.rightHandSide)) {
        return;
      }

      reporter.atNode(node.rightHandSide, code);
    });
  }

  _PrivateFieldTarget? _resolvePrivateMutableField(Expression expression) {
    final fieldName = switch (expression) {
      SimpleIdentifier identifier => identifier.name,
      PrefixedIdentifier identifier => identifier.identifier.name,
      PropertyAccess access => access.propertyName.name,
      _ => null,
    };

    if (fieldName == null || !fieldName.startsWith('_')) {
      return null;
    }

    final classDeclaration = expression
        .thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) {
      return null;
    }

    for (final member
        in classDeclaration.members.whereType<FieldDeclaration>()) {
      if (member.fields.isFinal || member.fields.isConst) {
        continue;
      }

      for (final variable in member.fields.variables) {
        if (variable.name.lexeme != fieldName) {
          continue;
        }

        return _PrivateFieldTarget(
          name: fieldName,
          typeAnnotation: member.fields.type,
          staticType: expression.staticType,
        );
      }
    }

    return null;
  }

  bool _containsDomainCollectionPayload(TypeAnnotation? typeAnnotation) {
    if (typeAnnotation is! NamedType) {
      return false;
    }

    final typeName = topLevelTypeName(typeAnnotation);
    if (typeName != 'List' &&
        typeName != 'Set' &&
        typeName != 'Iterable' &&
        typeName != 'Map') {
      return false;
    }

    final typeArguments = typeAnnotation.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.isEmpty) {
      return false;
    }

    return typeArguments.any(_containsDomainPayloadAnnotation);
  }

  bool _containsDomainCollectionPayloadFromDartType(DartType? type) {
    if (type is! InterfaceType) {
      return false;
    }

    final typeName = normalizeTypeName(type.getDisplayString());
    if (typeName != 'List' &&
        typeName != 'Set' &&
        typeName != 'Iterable' &&
        typeName != 'Map') {
      return false;
    }

    return type.typeArguments.any(_containsDomainPayload);
  }

  bool _containsDomainPayload(DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    final sourcePath = sourcePathOfDartType(type);
    if (sourcePath != null &&
        isDomainFilePath(sourcePath) &&
        !isDomainValueObjectFilePath(sourcePath)) {
      return true;
    }

    final typeName = normalizeTypeName(type.getDisplayString());
    if (typeName.endsWith('Model') ||
        typeName.endsWith('Match') ||
        typeName.endsWith('Recipient') ||
        typeName.endsWith('Resume')) {
      return true;
    }

    if (type.typeArguments.isEmpty) {
      return false;
    }

    return type.typeArguments.any(_containsDomainPayload);
  }

  bool _containsDomainPayloadAnnotation(TypeAnnotation annotation) {
    if (annotation is! NamedType) {
      return false;
    }

    final sourcePath = sourcePathOfTypeAnnotation(annotation);
    if (sourcePath != null &&
        isDomainFilePath(sourcePath) &&
        !isDomainValueObjectFilePath(sourcePath)) {
      return true;
    }

    final typeName = topLevelTypeName(annotation);
    if (typeName == null) {
      return false;
    }

    if (typeName.endsWith('Model') ||
        typeName.endsWith('Match') ||
        typeName.endsWith('Recipient') ||
        typeName.endsWith('Resume')) {
      return true;
    }

    final typeArguments = annotation.typeArguments?.arguments;
    if (typeArguments == null || typeArguments.isEmpty) {
      return false;
    }

    return typeArguments.any(_containsDomainPayloadAnnotation);
  }
}

class _PrivateFieldTarget {
  const _PrivateFieldTarget({
    required this.name,
    required this.typeAnnotation,
    required this.staticType,
  });

  final String name;
  final TypeAnnotation? typeAnnotation;
  final DartType? staticType;
}

class _DelegatedSnapshotReadDetector extends RecursiveAstVisitor<void> {
  _DelegatedSnapshotReadDetector({required this.functionBody});

  final FunctionBody functionBody;
  bool _found = false;
  final Set<String> _visitedLocalVariableNames = <String>{};
  Map<String, List<VariableDeclaration>>? _localDeclarationsByName;

  bool contains(Expression expression) {
    expression.accept(this);
    return _found;
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (_isDelegatedStreamSnapshotValueAccess(
      node.propertyName.name,
      node.target,
    )) {
      _found = true;
      return;
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_isDelegatedStreamSnapshotValueAccess(
      node.identifier.name,
      node.prefix,
    )) {
      _found = true;
      return;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_found) {
      return;
    }

    final variableName = node.name;
    if (variableName.isEmpty ||
        !_visitedLocalVariableNames.add('${node.offset}:$variableName')) {
      return;
    }

    final declaration = _resolveNearestLocalVariableDeclaration(
      variableName,
      node.offset,
    );
    final initializer = declaration?.initializer;
    if (initializer == null) {
      return;
    }

    initializer.accept(this);
  }

  bool _isDelegatedStreamSnapshotValueAccess(
    String propertyName,
    Expression? target,
  ) {
    if (propertyName != 'value' || target == null) {
      return false;
    }

    final targetType = target.staticType;
    if (targetType is! InterfaceType ||
        normalizeTypeName(targetType.getDisplayString()) != 'StreamValue') {
      return false;
    }

    return isDelegatedStreamTarget(target);
  }

  VariableDeclaration? _resolveNearestLocalVariableDeclaration(
    String variableName,
    int referenceOffset,
  ) {
    final declarations = _localVariableDeclarationsByName[variableName];
    if (declarations == null || declarations.isEmpty) {
      return null;
    }

    VariableDeclaration? nearest;
    for (final declaration in declarations) {
      if (declaration.offset >= referenceOffset) {
        continue;
      }
      if (nearest == null || declaration.offset > nearest.offset) {
        nearest = declaration;
      }
    }

    return nearest;
  }

  Map<String, List<VariableDeclaration>> get _localVariableDeclarationsByName {
    return _localDeclarationsByName ??= (() {
      final collector = _LocalVariableCollector();
      functionBody.accept(collector);
      return collector.declarationsByName;
    })();
  }
}

class _LocalVariableCollector extends RecursiveAstVisitor<void> {
  final Map<String, List<VariableDeclaration>> declarationsByName =
      <String, List<VariableDeclaration>>{};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final variableName = node.name.lexeme;
    if (variableName.isNotEmpty) {
      declarationsByName.putIfAbsent(
        variableName,
        () => <VariableDeclaration>[],
      )..add(node);
    }
    super.visitVariableDeclaration(node);
  }
}
