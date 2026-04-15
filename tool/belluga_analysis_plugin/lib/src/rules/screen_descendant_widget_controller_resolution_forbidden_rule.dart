// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class ScreenDescendantWidgetControllerResolutionForbiddenRule
    extends DartLintRule {
  ScreenDescendantWidgetControllerResolutionForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'screen_descendant_widget_controller_resolution_forbidden',
          problemMessage:
              'Screens or parent widgets cannot resolve a descendant widget controller outside its owning widget subtree.',
          correctionMessage:
              'Treatments: let the owning widget subtree resolve its widget controller; if parent/screen coordination is required, promote the state instead of resolving the descendant widget controller upward.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final currentPath = normalizePath(resolver.source.fullName);
    if (!isUiPresentationFilePath(currentPath) ||
        isGeneratedFilePath(currentPath)) {
      return;
    }

    final currentRoot = presentationRootKey(currentPath);
    if (currentRoot == null) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (!isGetItMethodInvocation(node)) {
        return;
      }

      if (_shouldReport(
        currentPath: currentPath,
        currentRoot: currentRoot,
        controllerSourcePath: sourcePathOfTypeArgument(node.typeArguments),
      )) {
        reporter.atNode(node.methodName, code);
      }
    });

    context.registry.addFunctionExpressionInvocation((node) {
      if (!isGetItCallableInvocation(node)) {
        return;
      }

      if (_shouldReport(
        currentPath: currentPath,
        currentRoot: currentRoot,
        controllerSourcePath: sourcePathOfTypeArgument(node.typeArguments),
      )) {
        reporter.atNode(node.function, code);
      }
    });
  }

  bool _shouldReport({
    required String currentPath,
    required String currentRoot,
    required String? controllerSourcePath,
  }) {
    if (controllerSourcePath == null ||
        !isPresentationWidgetControllerFilePath(controllerSourcePath)) {
      return false;
    }

    final controllerRoot = presentationRootKey(controllerSourcePath);
    if (controllerRoot == null || controllerRoot != currentRoot) {
      return false;
    }

    final ownerRoot = widgetControllerOwnerRootPath(controllerSourcePath);
    if (ownerRoot == null) {
      return false;
    }

    return !isPathWithinRoot(currentPath, ownerRoot);
  }
}
