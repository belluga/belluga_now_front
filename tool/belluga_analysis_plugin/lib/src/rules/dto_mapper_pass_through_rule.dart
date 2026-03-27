import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:belluga_analysis_plugin/src/path_utils.dart';
import 'package:belluga_analysis_plugin/src/type_utils.dart';

class DtoMapperPassThroughRule extends AnalysisRule {
  static const LintCode _code = LintCode(
    'dto_mapper_pass_through_forbidden',
    'Mapper methods converting DTO/primitives to domain are forbidden.',
    correctionMessage:
        'Treatments: remove mapper conversion methods and keep DTO->Domain conversion exclusively in DTO.toDomain().',
    severity: DiagnosticSeverity.WARNING,
  );

  DtoMapperPassThroughRule()
      : super(
          name: _code.lowerCaseName,
          description:
              'DTO mapper methods must not own pass-through conversion from DTO/primitives to domain payloads.',
        );

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(RuleVisitorRegistry registry, RuleContext context) {
    final visitor = _Visitor(this, context);
    registry.addMethodDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final DtoMapperPassThroughRule rule;
  final RuleContext context;

  bool get _isTargetFile {
    final current = context.currentUnit;
    if (current == null) {
      return false;
    }
    final path = normalizePath(current.file.path);
    return isDtoMapperFilePath(path) && !isGeneratedFilePath(path);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!_isTargetFile) {
      return;
    }
    if (!_returnsDomainPayload(node.returnType)) {
      return;
    }
    if (!_hasMapperLikeInput(node.parameters)) {
      return;
    }
    rule.reportAtToken(node.name);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (!_isTargetFile) {
      return;
    }
    if (!_returnsDomainPayload(node.returnType)) {
      return;
    }
    if (!_hasMapperLikeInput(node.functionExpression.parameters)) {
      return;
    }
    rule.reportAtToken(node.name);
  }

  bool _hasMapperLikeInput(FormalParameterList? parameters) {
    if (parameters == null) {
      return false;
    }

    for (final parameter in parameters.parameters) {
      final type = formalParameterType(parameter);
      if (containsDtoTypeAnnotation(type) ||
          containsForbiddenDomainPrimitiveType(type)) {
        return true;
      }
    }

    return false;
  }

  bool _returnsDomainPayload(TypeAnnotation? returnType) {
    if (!hasMeaningfulPayloadType(returnType)) {
      return false;
    }
    return !containsDtoTypeAnnotation(returnType);
  }
}
