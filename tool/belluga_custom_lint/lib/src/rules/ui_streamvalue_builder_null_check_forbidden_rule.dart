// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class UiStreamValueBuilderNullCheckForbiddenRule extends DartLintRule {
  UiStreamValueBuilderNullCheckForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'ui_streamvalue_builder_null_check_forbidden',
            problemMessage:
                'Do not null-check StreamValueBuilder value inside builder.',
            correctionMessage:
                'Treatments: use onNullWidget for null-state rendering and keep builder focused on non-null data.',
          ),
        );

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

    context.registry.addInstanceCreationExpression((node) {
      final typeName = normalizeTypeName(node.constructorName.type.toSource());
      if (typeName != 'StreamValueBuilder') {
        return;
      }

      final builderFunction = _extractBuilderFunction(node.argumentList);
      if (builderFunction == null) {
        return;
      }

      final valueParamName = _secondParameterName(builderFunction.parameters);
      if (valueParamName == null || valueParamName.isEmpty) {
        return;
      }

      final visitor = _BuilderNullCheckVisitor(valueParamName);
      builderFunction.body.visitChildren(visitor);
      for (final violation in visitor.violations) {
        reporter.atNode(violation, code);
      }
    });
  }

  FunctionExpression? _extractBuilderFunction(ArgumentList argumentList) {
    for (final argument in argumentList.arguments) {
      if (argument is! NamedExpression) {
        continue;
      }
      if (argument.name.label.name != 'builder') {
        continue;
      }
      final expression = argument.expression;
      if (expression is FunctionExpression) {
        return expression;
      }
    }
    return null;
  }

  String? _secondParameterName(FormalParameterList? parameters) {
    if (parameters == null || parameters.parameters.length < 2) {
      return null;
    }
    final parameter = parameters.parameters[1];
    if (parameter is SimpleFormalParameter) {
      return parameter.name?.lexeme;
    }
    if (parameter is DefaultFormalParameter) {
      final inner = parameter.parameter;
      if (inner is SimpleFormalParameter) {
        return inner.name?.lexeme;
      }
    }
    return null;
  }
}

class _BuilderNullCheckVisitor extends RecursiveAstVisitor<void> {
  _BuilderNullCheckVisitor(this.valueParamName);

  final String valueParamName;
  final List<AstNode> violations = <AstNode>[];

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operatorType = node.operator.type;
    if (operatorType == TokenType.EQ_EQ || operatorType == TokenType.BANG_EQ) {
      final leftIsValue = _isValueParam(node.leftOperand);
      final rightIsValue = _isValueParam(node.rightOperand);
      final leftIsNull = node.leftOperand is NullLiteral;
      final rightIsNull = node.rightOperand is NullLiteral;
      if ((leftIsValue && rightIsNull) || (rightIsValue && leftIsNull)) {
        violations.add(node);
      }
    }

    super.visitBinaryExpression(node);
  }

  bool _isValueParam(Expression expression) {
    return expression is SimpleIdentifier && expression.name == valueParamName;
  }
}

