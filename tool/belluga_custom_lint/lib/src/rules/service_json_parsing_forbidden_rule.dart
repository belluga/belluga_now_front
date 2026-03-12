// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class ServiceJsonParsingForbiddenRule extends DartLintRule {
  ServiceJsonParsingForbiddenRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'service_json_parsing_forbidden',
            problemMessage:
                'Services cannot parse raw JSON or hydrate DTOs directly.',
            correctionMessage:
                'Treatments: move transport parsing into DAO adapters and keep services focused on orchestration or outbound request shaping only.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isServiceFilePath(path) || isGeneratedFilePath(path)) {
      return;
    }

    _registerParsingVisitors(context, reporter);
  }

  void _registerParsingVisitors(
    CustomLintContext context,
    ErrorReporter reporter,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!_isForbiddenParsingConstructor(node)) {
        return;
      }

      reporter.atNode(node.constructorName, code);
    });

    context.registry.addFunctionExpressionInvocation((node) {
      final functionSource = node.function.toSource();
      if (functionSource != 'jsonDecode' && functionSource != 'json.decode') {
        return;
      }

      reporter.atNode(node.function, code);
    });

    context.registry.addMethodInvocation((node) {
      if (node.target?.toSource() != 'json' || node.methodName.name != 'decode') {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }

  bool _isForbiddenParsingConstructor(InstanceCreationExpression node) {
    final constructorName = node.constructorName.name?.name;
    if (constructorName != 'fromJson' && constructorName != 'fromMap') {
      return false;
    }

    final targetTypeName =
        normalizeTypeName(node.constructorName.type.toSource());
    if (constructorName == 'fromMap' && targetTypeName == 'FormData') {
      return false;
    }

    return true;
  }
}
