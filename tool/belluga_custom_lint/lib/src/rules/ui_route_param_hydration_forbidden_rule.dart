// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class UiRouteParamHydrationForbiddenRule extends DartLintRule {
  UiRouteParamHydrationForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_route_param_hydration_forbidden',
            problemMessage:
                'Screen lifecycle methods cannot hydrate feature data using widget route params.',
            correctionMessage:
                'Treatments: use RouteModelResolver for route-driven hydration; keep screens passive and trigger controller intents from resolved data only.',
          ),
        );

  static const _hydrationMethodNames = {
    'load',
    'loadData',
    'loadIfNeeded',
    'fetch',
    'fetchData',
    'hydrate',
    'resolve',
    'initialize',
    'refresh',
    'sync',
  };

  static const _detailHydrationHints = {
    'detail',
    'profile',
    'byid',
    'byslug',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isPresentationScreenFilePath(path)) {
      return;
    }

    context.registry.addMethodDeclaration((node) {
      final methodName = node.name.lexeme;
      if (methodName != 'initState' && methodName != 'didUpdateWidget') {
        return;
      }

      final visitor = _LifecycleHydrationInvocationVisitor(
        onViolation: (invocation) =>
            reporter.atNode(invocation.methodName, code),
      );
      node.body.visitChildren(visitor);
    });
  }
}

class _LifecycleHydrationInvocationVisitor extends RecursiveAstVisitor<void> {
  _LifecycleHydrationInvocationVisitor({
    required this.onViolation,
  });

  final void Function(MethodInvocation invocation) onViolation;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!_isHydrationMethodName(methodName)) {
      super.visitMethodInvocation(node);
      return;
    }

    if (_isSuperLifecycleCall(node)) {
      super.visitMethodInvocation(node);
      return;
    }

    final hasWidgetArgument = node.argumentList.arguments
        .any(_expressionUsesRouteParamWidgetReference);
    if (!hasWidgetArgument) {
      super.visitMethodInvocation(node);
      return;
    }

    if (_isControllerInvocation(node) || node.target == null) {
      onViolation(node);
    }

    super.visitMethodInvocation(node);
  }

  bool _isHydrationMethodName(String methodName) {
    final normalized = methodName.toLowerCase();
    final startsLikeHydration = UiRouteParamHydrationForbiddenRule
            ._hydrationMethodNames
            .contains(methodName) ||
        normalized.startsWith('load') ||
        normalized.startsWith('fetch') ||
        normalized.startsWith('hydrate') ||
        normalized.startsWith('resolve');
    if (!startsLikeHydration) {
      return false;
    }

    return UiRouteParamHydrationForbiddenRule._detailHydrationHints.any(
      normalized.contains,
    );
  }

  bool _isSuperLifecycleCall(MethodInvocation node) {
    return node.target?.toSource() == 'super' &&
        (node.methodName.name == 'initState' ||
            node.methodName.name == 'didUpdateWidget');
  }

  bool _isControllerInvocation(MethodInvocation node) {
    final targetTypeName = dartTypeName(node.realTarget?.staticType);
    if (isControllerTypeName(targetTypeName)) {
      return true;
    }

    final targetSource = (node.target?.toSource() ?? '').toLowerCase();
    if (targetSource.contains('controller')) {
      return true;
    }

    return false;
  }

  static const _routeParamHints = {
    'id',
    'slug',
    'code',
    'token',
    'query',
    'filter',
    'page',
    'cursor',
    'param',
  };

  bool _isRouteParamFieldName(String name) {
    final normalized = name.toLowerCase();
    if (_routeParamHints.contains(normalized)) {
      return true;
    }

    return normalized.endsWith('id') ||
        normalized.endsWith('slug') ||
        normalized.endsWith('code') ||
        normalized.endsWith('token');
  }

  bool _expressionUsesRouteParamWidgetReference(Expression expression) {
    if (expression is NamedExpression) {
      return _expressionUsesRouteParamWidgetReference(expression.expression);
    }

    if (expression is PropertyAccess) {
      final target = expression.target;
      if (target is SimpleIdentifier && target.name == 'widget') {
        return _isRouteParamFieldName(expression.propertyName.name);
      }
      if (target != null) {
        return _expressionUsesRouteParamWidgetReference(target);
      }
      return false;
    }

    if (expression is PrefixedIdentifier) {
      return expression.prefix.name == 'widget' &&
          _isRouteParamFieldName(expression.identifier.name);
    }

    if (expression is StringInterpolation) {
      return expression.elements.whereType<InterpolationExpression>().any(
            (element) =>
                _expressionUsesRouteParamWidgetReference(element.expression),
          );
    }

    if (expression is ConditionalExpression) {
      return _expressionUsesRouteParamWidgetReference(expression.condition) ||
          _expressionUsesRouteParamWidgetReference(expression.thenExpression) ||
          _expressionUsesRouteParamWidgetReference(expression.elseExpression);
    }

    if (expression is BinaryExpression) {
      return _expressionUsesRouteParamWidgetReference(expression.leftOperand) ||
          _expressionUsesRouteParamWidgetReference(expression.rightOperand);
    }

    if (expression is ParenthesizedExpression) {
      return _expressionUsesRouteParamWidgetReference(expression.expression);
    }

    if (expression is MethodInvocation) {
      final target = expression.target;
      if (target != null && _expressionUsesRouteParamWidgetReference(target)) {
        return true;
      }
      return expression.argumentList.arguments
          .any(_expressionUsesRouteParamWidgetReference);
    }

    return false;
  }
}
