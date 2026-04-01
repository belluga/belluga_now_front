// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class RepositoryModelStreamValueNullableRequiredRule extends DartLintRule {
  RepositoryModelStreamValueNullableRequiredRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'repository_model_streamvalue_nullable_required',
            problemMessage:
                'Repository StreamValue carrying *Model payload must be nullable at top-level.',
            correctionMessage:
                'Treatments: use StreamValue<T?> (for example StreamValue<List<EventModel>?>) so null can represent not-yet-fetched state.',
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

    context.registry.addVariableDeclaration((node) {
      if (node.thisOrAncestorOfType<FieldDeclaration>() == null) {
        return;
      }

      final payload = _streamValuePayload(node);
      if (payload == null) {
        return;
      }

      if (!_containsModelTypeAnnotation(payload)) {
        return;
      }

      if (_isTopLevelNullable(payload)) {
        return;
      }

      reporter.atNode(payload, code);
    });
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

  bool _isTopLevelNullable(TypeAnnotation annotation) {
    return annotation is NamedType && annotation.question != null;
  }
}
