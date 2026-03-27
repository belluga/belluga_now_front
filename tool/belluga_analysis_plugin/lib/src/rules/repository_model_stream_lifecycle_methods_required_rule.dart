// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class RepositoryModelStreamLifecycleMethodsRequiredRule extends DartLintRule {
  RepositoryModelStreamLifecycleMethodsRequiredRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'repository_model_stream_lifecycle_methods_required',
            problemMessage:
                'Repository with model StreamValue must expose initialize/populate and refresh methods returning void/Future<void>.',
            correctionMessage:
                'Treatments: add initialize/populate + refresh methods that update repository StreamValue and return void/Future<void>.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isRepositoryFilePath(path)) {
      return;
    }

    context.registry.addClassDeclaration((node) {
      if (!_ownsModelStreamValue(node)) {
        return;
      }

      final methods = node.members.whereType<MethodDeclaration>().toList();
      final hasInitializeOrPopulate =
          methods.any(_isInitializeOrPopulateMethod);
      final hasRefresh = methods.any(_isRefreshMethod);

      if (hasInitializeOrPopulate && hasRefresh) {
        return;
      }

      reporter.atNode(node, code);
    });
  }

  bool _ownsModelStreamValue(ClassDeclaration node) {
    for (final member in node.members) {
      if (member is! FieldDeclaration) {
        continue;
      }

      for (final variable in member.fields.variables) {
        final payload = _streamValuePayload(variable);
        if (payload == null) {
          continue;
        }

        if (_containsModelTypeAnnotation(payload)) {
          return true;
        }
      }
    }

    return false;
  }

  TypeAnnotation? _streamValuePayload(VariableDeclaration node) {
    final parent = node.parent;
    if (parent is VariableDeclarationList) {
      final declaredType = parent.type;
      if (declaredType is NamedType &&
          normalizeTypeName(declaredType.toSource()) == 'StreamValue') {
        final args = declaredType.typeArguments?.arguments;
        if (args != null && args.isNotEmpty) {
          return args.first;
        }
      }
    }

    final initializer = node.initializer;
    if (initializer is InstanceCreationExpression) {
      final createdType = initializer.constructorName.type;
      if (normalizeTypeName(createdType.toSource()) != 'StreamValue') {
        return null;
      }

      final args = createdType.typeArguments?.arguments;
      if (args == null || args.isEmpty) {
        return null;
      }

      return args.first;
    }

    if (initializer is MethodInvocation && initializer.target == null) {
      if (initializer.methodName.name != 'StreamValue') {
        return null;
      }
      final args = initializer.typeArguments?.arguments;
      if (args == null || args.isEmpty) {
        return null;
      }
      return args.first;
    }

    return null;
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

    final args = annotation.typeArguments?.arguments;
    if (args == null || args.isEmpty) {
      return false;
    }

    return args.any(_containsModelTypeAnnotation);
  }

  bool _isInitializeOrPopulateMethod(MethodDeclaration method) {
    if (method.isGetter || method.isSetter) {
      return false;
    }

    if (!_returnsVoidOrFutureVoid(method.returnType)) {
      return false;
    }

    final name = method.name.lexeme.toLowerCase();
    return name == 'init' ||
        name == 'initialize' ||
        name.startsWith('initialize') ||
        name == 'populate' ||
        name.startsWith('populate');
  }

  bool _isRefreshMethod(MethodDeclaration method) {
    if (method.isGetter || method.isSetter) {
      return false;
    }

    if (!_returnsVoidOrFutureVoid(method.returnType)) {
      return false;
    }

    final name = method.name.lexeme.toLowerCase();
    return name == 'refresh' || name.startsWith('refresh');
  }

  bool _returnsVoidOrFutureVoid(TypeAnnotation? type) {
    if (type == null) {
      return false;
    }

    final typeName = topLevelTypeName(type);
    if (typeName == 'void') {
      return true;
    }

    if (type is! NamedType) {
      return false;
    }

    if (typeName != 'Future' && typeName != 'FutureOr') {
      return false;
    }

    final args = type.typeArguments?.arguments;
    if (args == null || args.isEmpty) {
      return false;
    }

    return topLevelTypeName(args.first) == 'void';
  }
}
