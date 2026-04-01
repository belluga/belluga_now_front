// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ControllerOwnedStreamValueDisposeRequiredRule extends DartLintRule {
  ControllerOwnedStreamValueDisposeRequiredRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'controller_owned_streamvalue_dispose_required',
          problemMessage:
              'Controller-owned StreamValue field must be disposed in onDispose()/dispose().',
          correctionMessage:
              'Treatments: add `<streamField>.dispose()` inside controller onDispose()/dispose().',
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

    context.registry.addClassDeclaration((node) {
      final ownedStreamFields = _collectOwnedStreamFields(node);
      if (ownedStreamFields.isEmpty) {
        return;
      }

      final disposedFields = _collectDisposedFieldNames(node);
      for (final entry in ownedStreamFields.entries) {
        if (disposedFields.contains(entry.key)) {
          continue;
        }

        reporter.atNode(entry.value, code);
      }
    });
  }

  Map<String, VariableDeclaration> _collectOwnedStreamFields(
    ClassDeclaration node,
  ) {
    final result = <String, VariableDeclaration>{};

    for (final member in node.members) {
      if (member is! FieldDeclaration || member.isStatic) {
        continue;
      }

      final declaredType = member.fields.type;
      for (final variable in member.fields.variables) {
        if (!_isStreamValueField(
          variable: variable,
          declaredType: declaredType,
        )) {
          continue;
        }

        result[variable.name.lexeme] = variable;
      }
    }

    return result;
  }

  bool _isStreamValueField({
    required VariableDeclaration variable,
    required TypeAnnotation? declaredType,
  }) {
    if (declaredType != null &&
        normalizeTypeName(declaredType.toSource()) == 'StreamValue') {
      return true;
    }

    final initializer = variable.initializer;
    if (initializer is InstanceCreationExpression) {
      final createdType = initializer.constructorName.type;
      return normalizeTypeName(createdType.toSource()) == 'StreamValue';
    }

    if (initializer is MethodInvocation && initializer.target == null) {
      return initializer.methodName.name == 'StreamValue';
    }

    return dartTypeName(initializer?.staticType) == 'StreamValue';
  }

  Set<String> _collectDisposedFieldNames(ClassDeclaration node) {
    final disposed = <String>{};

    for (final member in node.members) {
      if (member is! MethodDeclaration || member.isStatic) {
        continue;
      }

      final methodName = member.name.lexeme;
      if (methodName != 'onDispose' && methodName != 'dispose') {
        continue;
      }

      member.body.visitChildren(
        _DisposeCallVisitor(onFieldDispose: disposed.add),
      );
    }

    return disposed;
  }
}

class _DisposeCallVisitor extends RecursiveAstVisitor<void> {
  _DisposeCallVisitor({required this.onFieldDispose});

  final void Function(String fieldName) onFieldDispose;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name != 'dispose') {
      super.visitMethodInvocation(node);
      return;
    }

    final target = node.realTarget;
    if (target is SimpleIdentifier) {
      onFieldDispose(target.name);
      super.visitMethodInvocation(node);
      return;
    }

    if (target is PropertyAccess && target.target is ThisExpression) {
      onFieldDispose(target.propertyName.name);
      super.visitMethodInvocation(node);
      return;
    }

    super.visitMethodInvocation(node);
  }
}
