import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' as analyzer;

enum ErrorSeverity { INFO, WARNING, ERROR }

class LintCode {
  const LintCode({
    required this.name,
    required this.problemMessage,
    this.correctionMessage,
    this.uniqueName,
    this.errorSeverity = ErrorSeverity.INFO,
  });

  final String name;
  final String problemMessage;
  final String? correctionMessage;
  final String? uniqueName;
  final ErrorSeverity errorSeverity;

  analyzer.LintCode toAnalyzerCode() {
    return analyzer.LintCode(
      name,
      problemMessage,
      correctionMessage: correctionMessage,
      uniqueName: uniqueName ?? name,
      severity: _toDiagnosticSeverity(errorSeverity),
    );
  }

  analyzer.DiagnosticSeverity _toDiagnosticSeverity(ErrorSeverity severity) {
    return switch (severity) {
      ErrorSeverity.INFO => analyzer.DiagnosticSeverity.INFO,
      ErrorSeverity.WARNING => analyzer.DiagnosticSeverity.WARNING,
      ErrorSeverity.ERROR => analyzer.DiagnosticSeverity.ERROR,
    };
  }
}

class CustomLintSource {
  const CustomLintSource(this.fullName);

  final String fullName;
}

class CustomLintResolver {
  const CustomLintResolver({required this.source});

  final CustomLintSource source;
}

class ErrorReporter {
  ErrorReporter(this._rule);

  final AnalysisRule _rule;

  void atNode(AstNode? node, LintCode errorCode) {
    _rule.reportAtNode(node);
  }

  void atOffset({
    required LintCode errorCode,
    required int offset,
    required int length,
  }) {
    _rule.reportAtOffset(offset, length);
  }
}

class CustomLintContext {
  CustomLintContext(this.registry);

  final LintRuleNodeRegistry registry;
}

class LintRuleNodeRegistry {
  LintRuleNodeRegistry(this._rule, this._registry);

  final DartLintRule _rule;
  final RuleVisitorRegistry _registry;

  void addAsExpression(void Function(AsExpression node) callback) {
    _registry.addAsExpression(_rule, _AsExpressionVisitor(callback));
  }

  void addAssignmentExpression(
    void Function(AssignmentExpression node) callback,
  ) {
    _registry.addAssignmentExpression(
      _rule,
      _AssignmentExpressionVisitor(callback),
    );
  }

  void addCatchClause(void Function(CatchClause node) callback) {
    _registry.addCatchClause(_rule, _CatchClauseVisitor(callback));
  }

  void addClassDeclaration(void Function(ClassDeclaration node) callback) {
    _registry.addClassDeclaration(_rule, _ClassDeclarationVisitor(callback));
  }

  void addCompilationUnit(void Function(CompilationUnit node) callback) {
    _registry.addCompilationUnit(_rule, _CompilationUnitVisitor(callback));
  }

  void addConstructorDeclaration(
    void Function(ConstructorDeclaration node) callback,
  ) {
    _registry.addConstructorDeclaration(
      _rule,
      _ConstructorDeclarationVisitor(callback),
    );
  }

  void addFieldDeclaration(void Function(FieldDeclaration node) callback) {
    _registry.addFieldDeclaration(_rule, _FieldDeclarationVisitor(callback));
  }

  void addFunctionDeclaration(void Function(FunctionDeclaration node) callback) {
    _registry.addFunctionDeclaration(
      _rule,
      _FunctionDeclarationVisitor(callback),
    );
  }

  void addFunctionExpressionInvocation(
    void Function(FunctionExpressionInvocation node) callback,
  ) {
    _registry.addFunctionExpressionInvocation(
      _rule,
      _FunctionExpressionInvocationVisitor(callback),
    );
  }

  void addImportDirective(void Function(ImportDirective node) callback) {
    _registry.addImportDirective(_rule, _ImportDirectiveVisitor(callback));
  }

  void addInstanceCreationExpression(
    void Function(InstanceCreationExpression node) callback,
  ) {
    _registry.addInstanceCreationExpression(
      _rule,
      _InstanceCreationExpressionVisitor(callback),
    );
  }

  void addIsExpression(void Function(IsExpression node) callback) {
    _registry.addIsExpression(_rule, _IsExpressionVisitor(callback));
  }

  void addMethodDeclaration(void Function(MethodDeclaration node) callback) {
    _registry.addMethodDeclaration(_rule, _MethodDeclarationVisitor(callback));
  }

  void addMethodInvocation(void Function(MethodInvocation node) callback) {
    _registry.addMethodInvocation(_rule, _MethodInvocationVisitor(callback));
  }

  void addNamedType(void Function(NamedType node) callback) {
    _registry.addNamedType(_rule, _NamedTypeVisitor(callback));
  }

  void addPrefixedIdentifier(
    void Function(PrefixedIdentifier node) callback,
  ) {
    _registry.addPrefixedIdentifier(
      _rule,
      _PrefixedIdentifierVisitor(callback),
    );
  }

  void addPropertyAccess(void Function(PropertyAccess node) callback) {
    _registry.addPropertyAccess(_rule, _PropertyAccessVisitor(callback));
  }

  void addSetOrMapLiteral(void Function(SetOrMapLiteral node) callback) {
    _registry.addSetOrMapLiteral(_rule, _SetOrMapLiteralVisitor(callback));
  }

  void addVariableDeclaration(void Function(VariableDeclaration node) callback) {
    _registry.addVariableDeclaration(
      _rule,
      _VariableDeclarationVisitor(callback),
    );
  }
}

abstract class DartLintRule extends AnalysisRule {
  DartLintRule({required this.code})
    : _diagnosticCode = code.toAnalyzerCode(),
      super(name: code.name, description: code.problemMessage);

  final LintCode code;
  final analyzer.LintCode _diagnosticCode;

  @override
  analyzer.LintCode get diagnosticCode => _diagnosticCode;

  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  );

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final resolver = CustomLintResolver(
      source: CustomLintSource(context.definingUnit.file.path),
    );
    final reporter = ErrorReporter(this);
    final lintContext = CustomLintContext(LintRuleNodeRegistry(this, registry));

    run(resolver, reporter, lintContext);
  }
}

class _AsExpressionVisitor extends SimpleAstVisitor<void> {
  _AsExpressionVisitor(this._callback);

  final void Function(AsExpression node) _callback;

  @override
  void visitAsExpression(AsExpression node) => _callback(node);
}

class _AssignmentExpressionVisitor extends SimpleAstVisitor<void> {
  _AssignmentExpressionVisitor(this._callback);

  final void Function(AssignmentExpression node) _callback;

  @override
  void visitAssignmentExpression(AssignmentExpression node) => _callback(node);
}

class _CatchClauseVisitor extends SimpleAstVisitor<void> {
  _CatchClauseVisitor(this._callback);

  final void Function(CatchClause node) _callback;

  @override
  void visitCatchClause(CatchClause node) => _callback(node);
}

class _ClassDeclarationVisitor extends SimpleAstVisitor<void> {
  _ClassDeclarationVisitor(this._callback);

  final void Function(ClassDeclaration node) _callback;

  @override
  void visitClassDeclaration(ClassDeclaration node) => _callback(node);
}

class _CompilationUnitVisitor extends SimpleAstVisitor<void> {
  _CompilationUnitVisitor(this._callback);

  final void Function(CompilationUnit node) _callback;

  @override
  void visitCompilationUnit(CompilationUnit node) => _callback(node);
}

class _ConstructorDeclarationVisitor extends SimpleAstVisitor<void> {
  _ConstructorDeclarationVisitor(this._callback);

  final void Function(ConstructorDeclaration node) _callback;

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _callback(node);
}

class _FieldDeclarationVisitor extends SimpleAstVisitor<void> {
  _FieldDeclarationVisitor(this._callback);

  final void Function(FieldDeclaration node) _callback;

  @override
  void visitFieldDeclaration(FieldDeclaration node) => _callback(node);
}

class _FunctionDeclarationVisitor extends SimpleAstVisitor<void> {
  _FunctionDeclarationVisitor(this._callback);

  final void Function(FunctionDeclaration node) _callback;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => _callback(node);
}

class _FunctionExpressionInvocationVisitor extends SimpleAstVisitor<void> {
  _FunctionExpressionInvocationVisitor(this._callback);

  final void Function(FunctionExpressionInvocation node) _callback;

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      _callback(node);
}

class _ImportDirectiveVisitor extends SimpleAstVisitor<void> {
  _ImportDirectiveVisitor(this._callback);

  final void Function(ImportDirective node) _callback;

  @override
  void visitImportDirective(ImportDirective node) => _callback(node);
}

class _InstanceCreationExpressionVisitor extends SimpleAstVisitor<void> {
  _InstanceCreationExpressionVisitor(this._callback);

  final void Function(InstanceCreationExpression node) _callback;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _callback(node);
}

class _IsExpressionVisitor extends SimpleAstVisitor<void> {
  _IsExpressionVisitor(this._callback);

  final void Function(IsExpression node) _callback;

  @override
  void visitIsExpression(IsExpression node) => _callback(node);
}

class _MethodDeclarationVisitor extends SimpleAstVisitor<void> {
  _MethodDeclarationVisitor(this._callback);

  final void Function(MethodDeclaration node) _callback;

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _callback(node);
}

class _MethodInvocationVisitor extends SimpleAstVisitor<void> {
  _MethodInvocationVisitor(this._callback);

  final void Function(MethodInvocation node) _callback;

  @override
  void visitMethodInvocation(MethodInvocation node) => _callback(node);
}

class _NamedTypeVisitor extends SimpleAstVisitor<void> {
  _NamedTypeVisitor(this._callback);

  final void Function(NamedType node) _callback;

  @override
  void visitNamedType(NamedType node) => _callback(node);
}

class _PrefixedIdentifierVisitor extends SimpleAstVisitor<void> {
  _PrefixedIdentifierVisitor(this._callback);

  final void Function(PrefixedIdentifier node) _callback;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) => _callback(node);
}

class _PropertyAccessVisitor extends SimpleAstVisitor<void> {
  _PropertyAccessVisitor(this._callback);

  final void Function(PropertyAccess node) _callback;

  @override
  void visitPropertyAccess(PropertyAccess node) => _callback(node);
}

class _SetOrMapLiteralVisitor extends SimpleAstVisitor<void> {
  _SetOrMapLiteralVisitor(this._callback);

  final void Function(SetOrMapLiteral node) _callback;

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) => _callback(node);
}

class _VariableDeclarationVisitor extends SimpleAstVisitor<void> {
  _VariableDeclarationVisitor(this._callback);

  final void Function(VariableDeclaration node) _callback;

  @override
  void visitVariableDeclaration(VariableDeclaration node) => _callback(node);
}
