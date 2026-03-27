// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class DomainPrimitiveFieldForbiddenRule extends DartLintRule {
  DomainPrimitiveFieldForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'domain_primitive_field_forbidden',
            problemMessage:
                'Domain fields cannot use primitive transport-oriented types directly.',
            correctionMessage:
                'Treatments: the ONLY acceptable solution is ValueObject. Use dedicated *Value classes extending ValueObject<T> (or approved bases like GenericStringValue/IntValue/DecimalValue/DateTimeValue/URIValue), keep validation inside ValueObjects, create a new ValueObject type whenever no existing base matches, use List/Set/Iterable of ValueObjects/domain-owned types only, and replace Map signatures with auxiliary domain models composed by ValueObjects. Typedef aliases are forbidden.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isDomainFilePath(path) ||
        isDomainValueObjectFilePath(path) ||
        isGeneratedFilePath(path)) {
      return;
    }

    context.registry.addFieldDeclaration((node) {
      if (node.isStatic) {
        return;
      }

      if (!containsForbiddenDomainPrimitiveType(node.fields.type)) {
        return;
      }

      for (final variable in node.fields.variables) {
        reporter.atOffset(
          errorCode: code,
          offset: variable.name.offset,
          length: variable.name.length,
        );
      }
    });

    context.registry.addConstructorDeclaration((node) {
      _reportForbiddenParameterTypes(node.parameters, reporter);
    });

    context.registry.addMethodDeclaration((node) {
      _reportForbiddenParameterTypes(node.parameters, reporter);
    });

    context.registry.addFunctionDeclaration((node) {
      _reportForbiddenParameterTypes(
        node.functionExpression.parameters,
        reporter,
      );
    });
  }

  void _reportForbiddenParameterTypes(
    FormalParameterList? parameters,
    ErrorReporter reporter,
  ) {
    if (parameters == null) {
      return;
    }

    for (final parameter in parameters.parameters) {
      final type = formalParameterType(parameter);
      if (!containsForbiddenDomainPrimitiveType(type) || type == null) {
        continue;
      }

      reporter.atOffset(
        errorCode: code,
        offset: type.offset,
        length: type.length,
      );
    }
  }
}
