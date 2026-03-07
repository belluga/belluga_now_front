// ignore_for_file: deprecated_member_use
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';

class UiNavigationAfterAwaitForbiddenRule extends DartLintRule {
  UiNavigationAfterAwaitForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_navigation_after_await_forbidden',
            problemMessage:
                'UI navigation after an async gap is forbidden.',
            correctionMessage:
                'Treatments: move async flow to controller intent/state, then navigate synchronously in UI reaction.',
          ),
        );

  static const _navigationMethods = {
    'push',
    'pop',
    'replace',
    'replaceAll',
    'navigate',
    'maybePop',
    'popUntil',
    'popUntilRoot',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isUiPresentationFilePath(path)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (!_isNavigationCall(node)) {
        return;
      }

      final body = _enclosingFunctionBody(node);
      if (body == null) {
        return;
      }

      if (!_hasAwaitBeforeOffset(body, node.offset)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }

  bool _isNavigationCall(MethodInvocation node) {
    final targetSource = node.target?.toSource();
    final methodName = node.methodName.name;

    if (targetSource == null) {
      return false;
    }

    if (targetSource == 'Navigator' || targetSource.startsWith('Navigator.')) {
      return true;
    }

    final looksLikeRouterCall =
        targetSource.toLowerCase().contains('router') &&
            _navigationMethods.contains(methodName);

    return looksLikeRouterCall;
  }

  FunctionBody? _enclosingFunctionBody(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is FunctionBody) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  bool _hasAwaitBeforeOffset(FunctionBody body, int offset) {
    final visitor = _AwaitBeforeOffsetVisitor(offset);
    body.visitChildren(visitor);
    return visitor.found;
  }
}

class _AwaitBeforeOffsetVisitor extends RecursiveAstVisitor<void> {
  _AwaitBeforeOffsetVisitor(this.offset);

  final int offset;
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (node.offset < offset) {
      found = true;
    }
    super.visitAwaitExpression(node);
  }
}
