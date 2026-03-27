import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:belluga_analysis_plugin/src/path_utils.dart';
import 'package:belluga_analysis_plugin/src/type_utils.dart';

class DomainPrimitiveFieldRule extends AnalysisRule {
  static const LintCode _code = LintCode(
    'domain_primitive_field_forbidden',
    'Domain fields cannot use primitive transport-oriented types directly.',
    correctionMessage:
        'Treatments: domain fields/constructors/methods must use ValueObjects or domain-owned types; typedef aliases do not remediate primitive usage; keep nullability and validation semantics explicit in those types.',
    severity: DiagnosticSeverity.WARNING,
  );

  DomainPrimitiveFieldRule()
      : super(
          name: _code.lowerCaseName,
          description:
              'Domain instance fields and API signatures must avoid primitive transport-oriented types.',
        );

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    registry.addFieldDeclaration(this, _Visitor(this, context));
    registry.addConstructorDeclaration(this, _Visitor(this, context));
    registry.addMethodDeclaration(this, _Visitor(this, context));
    registry.addFunctionDeclaration(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final DomainPrimitiveFieldRule rule;
  final RuleContext context;

  bool get _isTargetFile {
    final current = context.currentUnit;
    if (current == null) {
      return false;
    }
    final path = normalizePath(current.file.path);
    if (!isDomainFilePath(path) ||
        isDomainValueObjectFilePath(path) ||
        isGeneratedFilePath(path)) {
      return false;
    }
    return true;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!_isTargetFile || node.isStatic) {
      return;
    }
    if (!containsForbiddenDomainPrimitiveType(node.fields.type)) {
      return;
    }

    for (final variable in node.fields.variables) {
      rule.reportAtToken(variable.name);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!_isTargetFile) {
      return;
    }
    _reportForbiddenParameterTypes(node.parameters);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!_isTargetFile) {
      return;
    }
    _reportForbiddenParameterTypes(node.parameters);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!_isTargetFile) {
      return;
    }
    _reportForbiddenParameterTypes(node.functionExpression.parameters);
  }

  void _reportForbiddenParameterTypes(FormalParameterList? parameters) {
    if (parameters == null) {
      return;
    }

    for (final parameter in parameters.parameters) {
      final type = formalParameterType(parameter);
      if (type == null || !containsForbiddenDomainPrimitiveType(type)) {
        continue;
      }
      rule.reportAtNode(type);
    }
  }
}
