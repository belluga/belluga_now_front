// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/element/type.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ControllerRepositoryAsyncModelFetchForbiddenRule extends DartLintRule {
  ControllerRepositoryAsyncModelFetchForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'controller_repository_async_model_fetch_forbidden',
            problemMessage:
                'Controller must not call repository async methods that return payload directly.',
            correctionMessage:
                'Treatments: controller should trigger repository initialize/refresh (Future<void>) and consume repository-owned StreamValue delegation.',
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

    context.registry.addMethodInvocation((node) {
      final targetType = node.realTarget?.staticType;
      if (!_looksRepositoryTarget(targetType)) {
        return;
      }

      final invokedType = node.staticInvokeType;
      if (invokedType is! FunctionType) {
        return;
      }

      final returnType = invokedType.returnType;
      if (!_isAsyncCarrier(returnType)) {
        return;
      }

      if (!_hasAsyncPayload(returnType)) {
        return;
      }

      final methodName = node.methodName.name;
      final queryMethodSuffix = _queryMethodSuffix(methodName);
      if (queryMethodSuffix == null) {
        return;
      }

      if (targetType is! InterfaceType) {
        return;
      }

      if (!_hasRepositoryIntentCounterpart(targetType, queryMethodSuffix)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }

  bool _looksRepositoryTarget(DartType? type) {
    if (type is! InterfaceType) {
      return false;
    }

    final typeName = normalizeTypeName(type.getDisplayString());
    if (isRepositoryTypeName(typeName)) {
      return true;
    }

    if (type.typeArguments.isEmpty) {
      return false;
    }

    return type.typeArguments.any(_looksRepositoryTarget);
  }

  bool _isAsyncCarrier(DartType? type) {
    if (type is! InterfaceType) {
      return false;
    }

    final typeName = normalizeTypeName(type.getDisplayString());
    return typeName == 'Future' ||
        typeName == 'FutureOr' ||
        typeName == 'Stream';
  }

  bool _hasAsyncPayload(DartType? type) {
    if (type is! InterfaceType) {
      return false;
    }

    final typeArguments = type.typeArguments;
    if (typeArguments.isEmpty) {
      // Raw Future/Stream implies implicit dynamic payload.
      return true;
    }

    return typeArguments.any(_containsMeaningfulPayload);
  }

  bool _containsMeaningfulPayload(DartType? type) {
    if (type == null) {
      return false;
    }

    if (type is TypeParameterType) {
      return true;
    }

    if (type is! InterfaceType) {
      final typeName = normalizeTypeName(type.getDisplayString());
      return !_isVoidLike(typeName);
    }

    final typeName = normalizeTypeName(type.getDisplayString());
    if (_isVoidLike(typeName)) {
      return false;
    }

    if (typeName == 'Future' ||
        typeName == 'FutureOr' ||
        typeName == 'Stream') {
      if (type.typeArguments.isEmpty) {
        return true;
      }

      return type.typeArguments.any(_containsMeaningfulPayload);
    }

    return true;
  }

  bool _isVoidLike(String normalizedTypeName) {
    return normalizedTypeName == 'void' ||
        normalizedTypeName == 'Never' ||
        normalizedTypeName == 'Null';
  }

  String? _queryMethodSuffix(String methodName) {
    const queryPrefixes = <String>[
      'fetch',
      'get',
      'list',
      'search',
      'find',
      'query',
    ];

    for (final prefix in queryPrefixes) {
      if (!methodName.startsWith(prefix)) {
        continue;
      }
      final suffix = methodName.substring(prefix.length);
      if (suffix.isEmpty) {
        return null;
      }
      return suffix;
    }

    return null;
  }

  bool _hasRepositoryIntentCounterpart(
    InterfaceType repositoryType,
    String querySuffix,
  ) {
    final candidateMethodNames = <String>{
      'refresh$querySuffix',
      'load$querySuffix',
      'initialize$querySuffix',
    };

    final allTypes = <InterfaceType>{
      repositoryType,
      ...repositoryType.allSupertypes
    };
    for (final type in allTypes) {
      final methodNames =
          type.element.methods.map((method) => method.name).toSet();
      for (final candidate in candidateMethodNames) {
        if (methodNames.contains(candidate)) {
          return true;
        }
      }
    }

    return false;
  }
}
