// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class NestedGroupMembersFullListForbiddenRule extends DartLintRule {
  NestedGroupMembersFullListForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.warning,
          name: 'nested_group_members_full_list_forbidden',
          problemMessage:
              'Nested-group members must not expose or reconstruct a full-list API.',
          correctionMessage:
              'Treatments: keep cursor paging server-owned, expose one-page DAO calls and semantic repository load/load-more/search intents, and never drain every page in a loop.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isLibFilePath(path)) return;

    context.registry.addMethodDeclaration((node) {
      if (_isFullListName(node.name.lexeme)) {
        reporter.atNode(node, code);
      }

      final visitor = _NestedGroupMemberPageDrainVisitor();
      node.body.accept(visitor);
      for (final whileStatement in visitor.findings) {
        reporter.atNode(whileStatement, code);
      }
    });

    context.registry.addMethodInvocation((node) {
      if (_isFullListName(node.methodName.name)) {
        reporter.atNode(node, code);
      }
    });
  }

  bool _isFullListName(String rawName) {
    final name = rawName.replaceAll('_', '').toLowerCase();
    if (!name.contains('nestedgroupmembers')) return false;
    if (name.contains('page')) return false;

    return name.startsWith('get') ||
        name.startsWith('fetch') ||
        name.contains('allnestedgroupmembers') ||
        name.contains('nestedgroupmembersall') ||
        name.contains('fullnestedgroupmembers') ||
        name.contains('nestedgroupmembersfull');
  }
}

class _NestedGroupMemberPageDrainVisitor extends RecursiveAstVisitor<void> {
  final List<WhileStatement> findings = <WhileStatement>[];

  @override
  void visitWhileStatement(WhileStatement node) {
    final visitor = _NestedGroupMemberPageFetchVisitor();
    node.body.accept(visitor);
    if (visitor.found) findings.add(node);
    super.visitWhileStatement(node);
  }
}

class _NestedGroupMemberPageFetchVisitor extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'fetchNestedGroupMembersPageByPath') {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
