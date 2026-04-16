// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class ControllerControllerDependencyForbiddenRule extends DartLintRule {
  ControllerControllerDependencyForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'controller_controller_dependency_forbidden',
          problemMessage:
              'Controller files cannot inject or resolve other presentation controllers.',
          correctionMessage:
              'Treatments: replace controller-to-controller relay with repository contracts for shared state, or keep helper state local without DI/resolution through another controller.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final currentPath = normalizePath(resolver.source.fullName);
    if (!isPresentationControllerFilePath(currentPath) ||
        isGeneratedFilePath(currentPath)) {
      return;
    }

    context.registry.addConstructorDeclaration((node) {
      if (!_isInsideControllerClass(node)) {
        return;
      }

      final parameters = node.parameters.parameters;
      for (final parameter in parameters) {
        final type = _declaredTypeOf(parameter);
        if (!_isForeignPresentationControllerDependency(type, currentPath)) {
          continue;
        }

        reporter.atNode(parameter, code);
      }
    });

    context.registry.addMethodInvocation((node) {
      if (!_isInsideControllerClass(node) || !isGetItMethodInvocation(node)) {
        return;
      }

      if (!_isForeignPresentationControllerSourcePath(
        sourcePathOfTypeArgument(node.typeArguments),
        currentPath,
      )) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });

    context.registry.addFunctionExpressionInvocation((node) {
      if (!_isInsideControllerClass(node) || !isGetItCallableInvocation(node)) {
        return;
      }

      if (!_isForeignPresentationControllerSourcePath(
        sourcePathOfTypeArgument(node.typeArguments),
        currentPath,
      )) {
        return;
      }

      reporter.atNode(node.function, code);
    });
  }

  bool _isForeignPresentationControllerDependency(
    TypeAnnotation? type,
    String currentPath,
  ) {
    return _isForeignPresentationControllerSourcePath(
      sourcePathOfTypeAnnotation(type),
      currentPath,
    );
  }

  bool _isForeignPresentationControllerSourcePath(
    String? sourcePath,
    String currentPath,
  ) {
    if (sourcePath == null) {
      return false;
    }

    return sourcePath != currentPath &&
        isPresentationControllerFilePath(sourcePath);
  }

  bool _isInsideControllerClass(AstNode node) {
    final classNode = _enclosingClass(node);
    if (classNode == null) {
      return false;
    }

    return isControllerTypeName(classNode.name.lexeme);
  }

  ClassDeclaration? _enclosingClass(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ClassDeclaration) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  TypeAnnotation? _declaredTypeOf(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return _declaredTypeOf(parameter.parameter);
    }
    if (parameter is SimpleFormalParameter) {
      return parameter.type;
    }
    if (parameter is FieldFormalParameter) {
      return parameter.type;
    }
    if (parameter is SuperFormalParameter) {
      return parameter.type;
    }
    if (parameter is FunctionTypedFormalParameter) {
      return parameter.returnType;
    }
    return null;
  }
}
