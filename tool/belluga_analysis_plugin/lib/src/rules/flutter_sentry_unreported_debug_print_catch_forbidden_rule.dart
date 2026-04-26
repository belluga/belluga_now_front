// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart' show CommentToken;
import 'package:analyzer/dart/ast/visitor.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class FlutterSentryUnreportedDebugPrintCatchForbiddenRule extends DartLintRule {
  FlutterSentryUnreportedDebugPrintCatchForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'flutter_sentry_unreported_debug_print_catch_forbidden',
          problemMessage:
              'Catch blocks that log with debugPrint must also report unexpected failures to Sentry or rethrow.',
          correctionMessage:
              'Treatments: add an expected_control_flow marker for expected control flow, call SentryErrorReporter/Sentry.captureException before recovering, or rethrow/fail closed.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isLibFilePath(path) || isGeneratedFilePath(path)) {
      return;
    }

    context.registry.addCatchClause((node) {
      final visitor = _SentryCatchVisitor();
      node.body.accept(visitor);

      if (!visitor.hasDebugPrint ||
          visitor.hasSentryCapture ||
          visitor.propagatesFailure ||
          _hasExpectedControlFlowMarker(node)) {
        return;
      }

      for (final debugPrintNode in visitor.debugPrintNodes) {
        reporter.atNode(debugPrintNode, code);
      }
    });
  }
}

final class _SentryCatchVisitor extends RecursiveAstVisitor<void> {
  final List<SimpleIdentifier> debugPrintNodes = <SimpleIdentifier>[];
  bool hasSentryCapture = false;
  bool propagatesFailure = false;

  bool get hasDebugPrint => debugPrintNodes.isNotEmpty;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    final targetSource = node.target?.toSource();

    if (methodName == 'debugPrint') {
      debugPrintNodes.add(node.methodName);
    }

    if (_isSentryCapture(targetSource, methodName)) {
      hasSentryCapture = true;
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    propagatesFailure = true;
    super.visitThrowExpression(node);
  }

  @override
  void visitRethrowExpression(RethrowExpression node) {
    propagatesFailure = true;
    super.visitRethrowExpression(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Ignore nested closures; this rule targets direct catch/on control flow.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Ignore nested local functions; this rule targets direct catch/on control flow.
  }
}

bool _hasExpectedControlFlowMarker(CatchClause node) {
  var token = node.beginToken;
  final endToken = node.endToken;

  while (true) {
    var comment = token.precedingComments;
    while (comment != null) {
      if (comment.lexeme.contains('expected_control_flow')) {
        return true;
      }
      final nextComment = comment.next;
      comment = nextComment is CommentToken ? nextComment : null;
    }

    if (identical(token, endToken)) {
      break;
    }

    final next = token.next;
    if (next == null || identical(next, token)) {
      break;
    }
    token = next;
  }

  return false;
}

bool _isSentryCapture(String? targetSource, String methodName) {
  if (targetSource == 'Sentry' && methodName == 'captureException') {
    return true;
  }

  if (targetSource == 'SentryErrorReporter' &&
      (methodName == 'captureRecoverable' || methodName == 'captureFatal')) {
    return true;
  }

  return false;
}
