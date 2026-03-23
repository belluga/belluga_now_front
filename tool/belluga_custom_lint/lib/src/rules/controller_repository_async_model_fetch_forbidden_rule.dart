// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ControllerRepositoryAsyncModelFetchForbiddenRule extends DartLintRule {
  ControllerRepositoryAsyncModelFetchForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'controller_repository_async_model_fetch_forbidden',
            problemMessage:
                'Controller must not call repository async methods that return *Model payload directly.',
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

      if (!_containsModelPayload(returnType)) {
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

  bool _containsModelPayload(DartType? type) {
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

    return type.typeArguments.any(_containsModelPayload);
  }
}
