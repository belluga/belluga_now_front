// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class UiCrossFeatureControllerResolutionForbiddenRule extends DartLintRule {
  UiCrossFeatureControllerResolutionForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_cross_feature_controller_resolution_forbidden',
            problemMessage:
                'UI files cannot resolve controllers from another feature scope directly.',
            correctionMessage:
                'Treatments: resolve only same-feature controllers in UI; move cross-feature orchestration to shared/owning controller boundaries.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final currentPath = normalizePath(resolver.source.fullName);
    if (!isUiPresentationFilePath(currentPath)) {
      return;
    }

    final currentRoot = presentationRootKey(currentPath);
    if (currentRoot == null || isSharedPresentationRootKey(currentRoot)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (!isGetItMethodInvocation(node)) {
        return;
      }

      final typeName = firstTypeArgumentName(node.typeArguments);
      if (!isControllerTypeName(typeName)) {
        return;
      }

      final controllerSource =
          _controllerSourcePathFromTypeArgument(node.typeArguments);
      if (controllerSource == null) {
        return;
      }

      final controllerRoot = presentationRootKey(controllerSource);
      if (controllerRoot == null ||
          controllerRoot == currentRoot ||
          isSharedPresentationRootKey(controllerRoot)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });

    context.registry.addFunctionExpressionInvocation((node) {
      if (!isGetItCallableInvocation(node)) {
        return;
      }

      final typeName = firstTypeArgumentName(node.typeArguments);
      if (!isControllerTypeName(typeName)) {
        return;
      }

      final controllerSource =
          _controllerSourcePathFromTypeArgument(node.typeArguments);
      if (controllerSource == null) {
        return;
      }

      final controllerRoot = presentationRootKey(controllerSource);
      if (controllerRoot == null ||
          controllerRoot == currentRoot ||
          isSharedPresentationRootKey(controllerRoot)) {
        return;
      }

      reporter.atNode(node.function, code);
    });
  }

  String? _controllerSourcePathFromTypeArgument(
      TypeArgumentList? typeArguments) {
    final args = typeArguments?.arguments;
    if (args == null || args.isEmpty) {
      return null;
    }

    final type = args.first;
    if (type is! NamedType) {
      return null;
    }

    final element = type.element;
    if (element != null) {
      final source = element.firstFragment.libraryFragment?.source ??
          element.library?.firstFragment.source;
      if (source != null) {
        return normalizePath(source.fullName);
      }
    }

    final namedType = type.type;
    if (namedType is InterfaceType) {
      final interfaceElement = namedType.element3;
      final interfaceSource = interfaceElement.library.firstFragment.source;
      return normalizePath(interfaceSource.fullName);
    }

    return null;
  }
}
