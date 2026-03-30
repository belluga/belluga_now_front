// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ControllerDelegatedStreamValueDisposeForbiddenRule extends DartLintRule {
  ControllerDelegatedStreamValueDisposeForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'controller_delegated_streamvalue_dispose_forbidden',
          problemMessage:
              'Controller must not dispose delegated StreamValue from repository/service contracts.',
          correctionMessage:
              'Treatments: dispose only controller-owned StreamValue fields; keep delegated repository/service streams alive.',
        ),
      );

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

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'dispose') {
        return;
      }

      final target = node.realTarget;
      if (target == null) {
        return;
      }

      if (dartTypeName(target.staticType) != 'StreamValue') {
        return;
      }

      if (_isExternalStreamTarget(target)) {
        reporter.atNode(node.methodName, code);
        return;
      }

      final accessor = _resolveAccessor(target);
      if (accessor == null) {
        return;
      }

      if (_isExplicitStreamGetter(accessor)) {
        reporter.atNode(node.methodName, code);
      }
    });
  }

  bool _isExternalStreamTarget(Expression target) {
    if (target is PropertyAccess) {
      final owner = target.target;
      return owner != null && owner is! ThisExpression;
    }

    if (target is PrefixedIdentifier) {
      return true;
    }

    return false;
  }

  PropertyAccessorElement? _resolveAccessor(Expression target) {
    if (target is SimpleIdentifier) {
      final element = target.element;
      return element is PropertyAccessorElement ? element : null;
    }

    if (target is PropertyAccess) {
      final element = target.propertyName.element;
      return element is PropertyAccessorElement ? element : null;
    }

    if (target is PrefixedIdentifier) {
      final element = target.identifier.element;
      return element is PropertyAccessorElement ? element : null;
    }

    return null;
  }

  bool _isExplicitStreamGetter(PropertyAccessorElement accessor) {
    return !accessor.isSynthetic &&
        dartTypeName(accessor.returnType) == 'StreamValue';
  }
}
