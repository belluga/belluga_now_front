// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';

class RepositoryServiceCatchReturnFallbackForbiddenRule extends DartLintRule {
  RepositoryServiceCatchReturnFallbackForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'repository_service_catch_return_fallback_forbidden',
            problemMessage:
                'Repositories/services cannot return fallback values inside catch/on handlers.',
            correctionMessage:
                'Treatments: propagate failure to controller/view layer; do not hide backend/runtime failures by returning fallback models/collections/flags in repository/service.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    final isRepositoryOrService =
        isRepositoryFilePath(path) || isServiceFilePath(path);
    if (!isRepositoryOrService || isGeneratedFilePath(path)) {
      return;
    }

    context.registry.addCatchClause((node) {
      final returns = <ReturnStatement>[];
      node.body.accept(_CatchReturnVisitor(returns));

      for (final returnStatement in returns) {
        reporter.atNode(returnStatement, code);
      }
    });
  }
}

final class _CatchReturnVisitor extends RecursiveAstVisitor<void> {
  _CatchReturnVisitor(this._returns);

  final List<ReturnStatement> _returns;

  @override
  void visitReturnStatement(ReturnStatement node) {
    _returns.add(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Ignore nested closures; rule targets direct catch/on control flow.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Ignore nested local functions; rule targets direct catch/on control flow.
  }
}
