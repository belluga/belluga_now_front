// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class RepositoryRawPayloadMapForbiddenRule extends DartLintRule {
  RepositoryRawPayloadMapForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'repository_raw_payload_map_forbidden',
            problemMessage:
                'Repositories cannot own raw payload map typing/parsing/building.',
            correctionMessage:
                'Treatments: 1) move envelope parsing to DAO/DTO decoder, '
                '2) move request payload assembly to DAO request encoder/builder, '
                '3) keep repository methods DTO/domain-typed only. '
                'Reference: tool/belluga_analysis_plugin/docs/rules.md#repository_raw_payload_map_forbidden',
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

    final reportedOffsets = <int>{};

    void reportIfNeeded(AstNode node) {
      if (reportedOffsets.add(node.offset)) {
        reporter.atNode(node, code);
      }
    }

    context.registry.addFieldDeclaration((node) {
      final type = node.fields.type;
      if (containsRepositoryRawPayloadMapType(type) && type != null) {
        reportIfNeeded(type);
      }
    });

    context.registry.addVariableDeclaration((node) {
      final parent = node.parent;
      if (parent is! VariableDeclarationList) {
        return;
      }

      final type = parent.type;
      if (containsRepositoryRawPayloadMapType(type) && type != null) {
        reportIfNeeded(type);
      }
    });

    context.registry.addMethodDeclaration((node) {
      final returnType = node.returnType;
      if (containsRepositoryRawPayloadMapType(returnType) &&
          returnType != null) {
        reportIfNeeded(returnType);
      }

      _reportForbiddenParameterTypes(
        parameters: node.parameters,
        reportIfNeeded: reportIfNeeded,
      );
    });

    context.registry.addFunctionDeclaration((node) {
      final returnType = node.returnType;
      if (containsRepositoryRawPayloadMapType(returnType) &&
          returnType != null) {
        reportIfNeeded(returnType);
      }

      _reportForbiddenParameterTypes(
        parameters: node.functionExpression.parameters,
        reportIfNeeded: reportIfNeeded,
      );
    });

    context.registry.addAsExpression((node) {
      final type = node.type;
      if (containsRepositoryRawPayloadMapType(type)) {
        reportIfNeeded(type);
      }
    });

    context.registry.addIsExpression((node) {
      final type = node.type;
      if (containsRepositoryRawPayloadMapType(type)) {
        reportIfNeeded(type);
      }
    });

    context.registry.addInstanceCreationExpression((node) {
      final type = node.constructorName.type;
      if (containsRepositoryRawPayloadMapType(type)) {
        reportIfNeeded(type);
      }
    });

    context.registry.addSetOrMapLiteral((node) {
      if (!node.isMap) {
        return;
      }

      final typeArguments = node.typeArguments;
      if (!_containsForbiddenMapTypeArguments(typeArguments) ||
          typeArguments == null) {
        return;
      }

      reportIfNeeded(typeArguments);
    });

    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;

      if (methodName == 'cast' &&
          _containsForbiddenCastTypeArguments(node.typeArguments)) {
        reportIfNeeded(node.typeArguments!);
        return;
      }

      if (methodName == 'whereType' &&
          _containsForbiddenWhereTypeArguments(node.typeArguments)) {
        reportIfNeeded(node.typeArguments!);
      }
    });
  }

  void _reportForbiddenParameterTypes({
    required FormalParameterList? parameters,
    required void Function(AstNode node) reportIfNeeded,
  }) {
    if (parameters == null) {
      return;
    }

    for (final parameter in parameters.parameters) {
      final type = _parameterType(parameter);
      if (containsRepositoryRawPayloadMapType(type) && type != null) {
        reportIfNeeded(type);
      }
    }
  }

  bool _containsForbiddenMapTypeArguments(TypeArgumentList? typeArguments) {
    if (typeArguments == null || typeArguments.arguments.length < 2) {
      return false;
    }

    final keyType = typeArguments.arguments[0];
    final valueType = typeArguments.arguments[1];
    return topLevelTypeName(keyType) == 'String' &&
        (topLevelTypeName(valueType) == 'Object' ||
            topLevelTypeName(valueType) == 'dynamic' ||
            containsRepositoryRawPayloadMapType(valueType));
  }

  bool _containsForbiddenCastTypeArguments(TypeArgumentList? typeArguments) {
    if (typeArguments == null || typeArguments.arguments.length < 2) {
      return false;
    }
    final keyType = typeArguments.arguments[0];
    final valueType = typeArguments.arguments[1];
    final keyTypeName = topLevelTypeName(keyType);
    final valueTypeName = topLevelTypeName(valueType);
    if (keyTypeName != 'String') {
      return false;
    }
    if (valueTypeName == 'Object' || valueTypeName == 'dynamic') {
      return true;
    }
    return containsRepositoryRawPayloadMapType(valueType);
  }

  bool _containsForbiddenWhereTypeArguments(TypeArgumentList? typeArguments) {
    if (typeArguments == null || typeArguments.arguments.isEmpty) {
      return false;
    }
    return containsRepositoryRawPayloadMapType(typeArguments.arguments.first);
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
