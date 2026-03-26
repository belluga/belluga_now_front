// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class UiBuildSideEffectsForbiddenRule extends DartLintRule {
  UiBuildSideEffectsForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_build_side_effects_forbidden',
            problemMessage:
                'build/didChangeDependencies cannot trigger side-effect operations.',
            correctionMessage:
                'Treatments: move fetch/IO/logging side effects to controller lifecycle/intents; keep build methods pure.',
          ),
        );

  static const _sideEffectMethodNames = {
    'load',
    'loadData',
    'fetch',
    'fetchData',
    'request',
    'post',
    'put',
    'patch',
    'delete',
    'refresh',
    'initialize',
    'init',
    'sync',
    'send',
    'track',
    'log',
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

    context.registry.addMethodDeclaration((node) {
      final methodName = node.name.lexeme;
      if (methodName != 'build' && methodName != 'didChangeDependencies') {
        return;
      }

      final visitor = _BuildSideEffectVisitor(
        onViolation: (invocation) => reporter.atNode(invocation.methodName, code),
        sideEffectMethodNames: _sideEffectMethodNames,
      );
      node.body.visitChildren(visitor);
    });
  }
}

class _BuildSideEffectVisitor extends RecursiveAstVisitor<void> {
  _BuildSideEffectVisitor({
    required this.onViolation,
    required this.sideEffectMethodNames,
  });

  final void Function(MethodInvocation invocation) onViolation;
  final Set<String> sideEffectMethodNames;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final targetSource = node.target?.toSource() ?? '';
    final methodName = node.methodName.name;

    if (targetSource == 'super' && methodName == 'didChangeDependencies') {
      super.visitMethodInvocation(node);
      return;
    }

    if (isGetItMethodInvocation(node)) {
      onViolation(node);
      super.visitMethodInvocation(node);
      return;
    }

    final targetTypeName = dartTypeName(node.realTarget?.staticType);
    if (isDataSourceTypeName(targetTypeName)) {
      onViolation(node);
      super.visitMethodInvocation(node);
      return;
    }

    if (sideEffectMethodNames.contains(methodName)) {
      onViolation(node);
    }

    super.visitMethodInvocation(node);
  }
}
