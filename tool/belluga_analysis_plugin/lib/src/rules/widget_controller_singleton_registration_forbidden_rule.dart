// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class WidgetControllerSingletonRegistrationForbiddenRule extends DartLintRule {
  WidgetControllerSingletonRegistrationForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'widget_controller_singleton_registration_forbidden',
          problemMessage:
              'Widget controllers cannot be registered with singleton lifecycle when that registration leaks them above the widget subtree.',
          correctionMessage:
              'Treatments: keep widget controllers widget-scoped/factory-managed by default; if lifecycle must extend beyond one build, document the exception canonically instead of registering the widget controller as a singleton.',
        ),
      );

  static const _directSingletonRegistrationMethodNames = {
    'registerLazySingleton',
    'registerLazySingletonAsync',
    'registerSingleton',
    'registerSingletonAsync',
    'registerSingletonWithDependencies',
  };

  static const _moduleSingletonRegistrationMethodNames = {
    'registerLazySingleton',
    'registerLazySingletonAsync',
    'registerSingleton',
    'registerSingletonAsync',
    'registerSingletonWithDependencies',
  };

  static const _moduleSettingsSingletonHelperMethodNames = {
    '_registerIfAbsent',
    '_registerLazySingletonIfAbsent',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final currentPath = normalizePath(resolver.source.fullName);
    if (!isLibFilePath(currentPath) || isGeneratedFilePath(currentPath)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (!_isSingletonLifecycleRegistration(node, currentPath)) {
        return;
      }

      final registeredSourcePath = _registeredTypeSourcePath(node);
      if (!isPresentationWidgetControllerFilePath(registeredSourcePath ?? '')) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }

  bool _isSingletonLifecycleRegistration(MethodInvocation node, String path) {
    if (isGetItRegistrationMethodInvocation(node)) {
      return _directSingletonRegistrationMethodNames.contains(
        node.methodName.name,
      );
    }

    if (node.target != null) {
      return false;
    }

    if (_moduleSingletonRegistrationMethodNames.contains(
      node.methodName.name,
    )) {
      return _extendsModuleContract(_enclosingClass(node));
    }

    if (_moduleSettingsSingletonHelperMethodNames.contains(
      node.methodName.name,
    )) {
      return isModuleSettingsFilePath(path);
    }

    return false;
  }

  String? _registeredTypeSourcePath(MethodInvocation node) {
    final sourceFromTypeArgument = sourcePathOfTypeArgument(node.typeArguments);
    if (sourceFromTypeArgument != null) {
      return sourceFromTypeArgument;
    }

    final arguments = node.argumentList.arguments;
    if (arguments.isEmpty) {
      return null;
    }

    final firstArgument = arguments.first;
    final sourceFromStaticType = sourcePathOfDartType(firstArgument.staticType);
    if (sourceFromStaticType != null) {
      return sourceFromStaticType;
    }

    if (firstArgument is FunctionExpression) {
      return _sourcePathFromFunctionExpression(firstArgument);
    }

    return null;
  }

  String? _sourcePathFromFunctionExpression(FunctionExpression expression) {
    final body = expression.body;
    if (body is ExpressionFunctionBody) {
      final expressionBody = body.expression;
      if (expressionBody is InstanceCreationExpression) {
        return sourcePathOfTypeAnnotation(expressionBody.constructorName.type);
      }
    }

    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is! ReturnStatement) {
          continue;
        }

        final returnedExpression = statement.expression;
        if (returnedExpression is InstanceCreationExpression) {
          return sourcePathOfTypeAnnotation(
            returnedExpression.constructorName.type,
          );
        }
      }
    }

    return null;
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

  bool _extendsModuleContract(ClassDeclaration? classNode) {
    if (classNode == null) {
      return false;
    }

    final extendsClause = classNode.extendsClause;
    if (extendsClause == null) {
      return false;
    }

    return normalizeTypeName(extendsClause.superclass.toSource()) ==
        'ModuleContract';
  }
}
