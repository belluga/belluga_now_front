// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class UiControllerOwnershipForbiddenRule extends DartLintRule {
  UiControllerOwnershipForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_controller_ownership_forbidden',
            problemMessage:
                'Screen files cannot own UI controllers/keys; auxiliary widgets can own them only if they do not interact with feature controllers.',
            correctionMessage:
                'Treatments: in screens, move ownership to feature controller. In auxiliary widgets, keep local only when isolated from controller interactions.',
          ),
        );

  static const _blockedTypes = {
    'TextEditingController',
    'FocusNode',
    'ScrollController',
    'AnimationController',
    'PageController',
    'TabController',
    'TransformationController',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    final isScreenFile = isPresentationScreenFilePath(path);
    final isWidgetFile = isPresentationWidgetFilePath(path);
    if (!isScreenFile && !isWidgetFile) {
      return;
    }

    final ownedUiControllerSymbols = <String>{};

    context.registry.addVariableDeclaration((node) {
      final declaration = _declarationInfo(node);
      if (declaration == null) {
        return;
      }

      if (isScreenFile) {
        reporter.atNode(declaration.reportNode, code);
        return;
      }

      ownedUiControllerSymbols.add(node.name.lexeme);
    });

    context.registry.addMethodInvocation((node) {
      if (!isWidgetFile) {
        return;
      }

      if (!_isControllerInvocation(node)) {
        return;
      }

      for (final argument in node.argumentList.arguments) {
        if (_referencesOwnedUiController(argument, ownedUiControllerSymbols)) {
          reporter.atNode(argument, code);
          return;
        }
      }
    });
  }

  _OwnershipDeclaration? _declarationInfo(VariableDeclaration node) {
    final parent = node.parent;
    if (parent is! VariableDeclarationList) {
      return null;
    }

    final declaredType = normalizeTypeName(parent.type?.toSource() ?? '');
    final declaredSource = parent.type?.toSource() ?? '';
    if (_isBlockedType(declaredType, declaredSource)) {
      return _OwnershipDeclaration(parent.type ?? node);
    }

    final initializer = node.initializer;
    if (initializer is InstanceCreationExpression) {
      final createdType = normalizeTypeName(
        initializer.constructorName.type.toSource(),
      );
      final createdSource = initializer.constructorName.type.toSource();
      if (_isBlockedType(createdType, createdSource)) {
        return _OwnershipDeclaration(initializer.constructorName.type);
      }
    }

    if (initializer is MethodInvocation && initializer.target == null) {
      final createdType = initializer.methodName.name;
      final createdSource = initializer.toSource();
      if (_isBlockedType(createdType, createdSource)) {
        return _OwnershipDeclaration(initializer.methodName);
      }
    }

    return null;
  }

  bool _isBlockedType(String typeName, String source) {
    if (_blockedTypes.contains(typeName)) {
      return true;
    }

    return typeName == 'GlobalKey' && source.contains('FormState');
  }

  bool _isControllerInvocation(MethodInvocation node) {
    final targetTypeName = dartTypeName(node.realTarget?.staticType);
    if (isControllerTypeName(targetTypeName)) {
      return true;
    }

    final target = node.target;
    if (target is SimpleIdentifier) {
      return _looksLikeFeatureControllerName(target.name);
    }

    if (target is PropertyAccess) {
      return _looksLikeFeatureControllerName(target.target?.toSource() ?? '');
    }

    return false;
  }

  bool _looksLikeFeatureControllerName(String name) {
    final normalized = name.replaceAll('?', '');
    if (!normalized.endsWith('Controller')) {
      return false;
    }

    return !_blockedTypes.contains(normalizeTypeName(normalized));
  }

  bool _referencesOwnedUiController(
    Expression expression,
    Set<String> ownedSymbols,
  ) {
    final source = expression.toSource();
    for (final symbol in ownedSymbols) {
      if (_containsIdentifier(source, symbol)) {
        return true;
      }
    }

    return false;
  }

  bool _containsIdentifier(String source, String identifier) {
    final escaped = RegExp.escape(identifier);
    final regex = RegExp(r'\b' + escaped + r'\b');
    return regex.hasMatch(source);
  }
}

class _OwnershipDeclaration {
  const _OwnershipDeclaration(this.reportNode);

  final AstNode reportNode;
}
