import 'package:analyzer/dart/ast/ast.dart';
import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ControllerStreamValueParameterForbiddenRule extends DartLintRule {
  ControllerStreamValueParameterForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'controller_streamvalue_parameter_forbidden',
          problemMessage:
              'Controller methods must not accept StreamValue parameters.',
          correctionMessage:
              'Treatments: mutate controller-owned StreamValue at explicit field call sites; keep delegated repository/service streams read-only; if a helper is needed, pass a closure or create a semantic setter bound to the owned field instead of accepting StreamValue as a parameter.',
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

    context.registry.addMethodDeclaration((node) {
      _reportForbiddenParameters(node.parameters, reporter);
    });

    context.registry.addFunctionDeclaration((node) {
      _reportForbiddenParameters(node.functionExpression.parameters, reporter);
    });
  }

  void _reportForbiddenParameters(
    FormalParameterList? parameters,
    ErrorReporter reporter,
  ) {
    if (parameters == null) {
      return;
    }

    for (final parameter in parameters.parameters) {
      final type = _declaredTypeOf(parameter);
      if (topLevelTypeName(type) == 'StreamValue') {
        reporter.atNode(parameter, code);
      }
    }
  }

  TypeAnnotation? _declaredTypeOf(FormalParameter parameter) {
    if (parameter is DefaultFormalParameter) {
      return _declaredTypeOf(parameter.parameter);
    }
    if (parameter is SimpleFormalParameter) {
      return parameter.type;
    }
    if (parameter is FieldFormalParameter) {
      return parameter.type;
    }
    if (parameter is SuperFormalParameter) {
      return parameter.type;
    }
    if (parameter is FunctionTypedFormalParameter) {
      return parameter.returnType;
    }
    return null;
  }
}
