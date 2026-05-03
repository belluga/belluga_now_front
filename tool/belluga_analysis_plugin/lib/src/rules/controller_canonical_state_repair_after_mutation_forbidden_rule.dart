// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class ControllerCanonicalStateRepairAfterMutationForbiddenRule
    extends DartLintRule {
  ControllerCanonicalStateRepairAfterMutationForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'controller_canonical_state_repair_after_mutation_forbidden',
          problemMessage:
              'Controller must not repair canonical repository state after repository mutations.',
          correctionMessage:
              'Treatments: make the mutation owner repository leave confirmed-attendance/pending-invite caches consistent and consume repository streams in the controller.',
        ),
      );

  static const Set<String> _mutationMethodNames = <String>{
    'confirmEventAttendance',
    'unconfirmEventAttendance',
    'acceptInvite',
    'acceptInviteByCode',
    'declineInvite',
  };

  static const Set<String> _repairMethodNames = <String>{
    'refreshConfirmedOccurrenceIds',
    'refreshPendingInvites',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isPresentationControllerFilePath(path)) {
      return;
    }

    context.registry.addClassDeclaration((node) {
      final repairHelperNames = _collectRepairHelperNames(node);

      for (final method in node.members.whereType<MethodDeclaration>()) {
        final body = method.body;
        final directCalls = _collectDirectRepositoryCalls(body);
        final helperCalls = _collectLocalHelperCalls(body);
        final firstMutationOffset = _firstMutationOffset(directCalls);
        if (firstMutationOffset == null) {
          continue;
        }

        for (final call in directCalls) {
          if (!_repairMethodNames.contains(call.methodName)) {
            continue;
          }
          if (call.offset <= firstMutationOffset) {
            continue;
          }
          reporter.atNode(call.node.methodName, code);
        }

        for (final helperCall in helperCalls) {
          if (!repairHelperNames.contains(helperCall.methodName)) {
            continue;
          }
          if (helperCall.offset <= firstMutationOffset) {
            continue;
          }
          reporter.atNode(helperCall.node.methodName, code);
        }
      }
    });
  }

  Set<String> _collectRepairHelperNames(ClassDeclaration node) {
    final names = <String>{};
    for (final method in node.members.whereType<MethodDeclaration>()) {
      final directCalls = _collectDirectRepositoryCalls(method.body);
      if (directCalls.any(
        (call) => _repairMethodNames.contains(call.methodName),
      )) {
        names.add(method.name.lexeme);
      }
    }
    return names;
  }

  List<_MethodCallRecord> _collectDirectRepositoryCalls(FunctionBody body) {
    final visitor = _MethodCallCollector(includeLocalHelperCalls: false);
    body.accept(visitor);
    return visitor.records;
  }

  List<_MethodCallRecord> _collectLocalHelperCalls(FunctionBody body) {
    final visitor = _MethodCallCollector(includeLocalHelperCalls: true);
    body.accept(visitor);
    return visitor.records;
  }

  int? _firstMutationOffset(List<_MethodCallRecord> calls) {
    int? firstOffset;
    for (final call in calls) {
      if (!_mutationMethodNames.contains(call.methodName)) {
        continue;
      }
      if (firstOffset == null || call.offset < firstOffset) {
        firstOffset = call.offset;
      }
    }
    return firstOffset;
  }
}

class _MethodCallCollector extends RecursiveAstVisitor<void> {
  _MethodCallCollector({required this.includeLocalHelperCalls});

  final bool includeLocalHelperCalls;
  final List<_MethodCallRecord> records = <_MethodCallRecord>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.realTarget;
    if (!includeLocalHelperCalls && target == null) {
      super.visitMethodInvocation(node);
      return;
    }
    if (includeLocalHelperCalls && target != null) {
      super.visitMethodInvocation(node);
      return;
    }
    records.add(
      _MethodCallRecord(
        node: node,
        methodName: node.methodName.name,
        offset: node.offset,
      ),
    );
    super.visitMethodInvocation(node);
  }
}

class _MethodCallRecord {
  const _MethodCallRecord({
    required this.node,
    required this.methodName,
    required this.offset,
  });

  final MethodInvocation node;
  final String methodName;
  final int offset;
}
