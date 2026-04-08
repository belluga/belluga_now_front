// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class RepositoryContractPaginationControlsForbiddenRule extends DartLintRule {
  RepositoryContractPaginationControlsForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'repository_contract_pagination_controls_forbidden',
          problemMessage:
              'Repository contract must not expose raw pagination controls or delegated pagination state.',
          correctionMessage:
              'Treatments: keep page/cursor/has-more bookkeeping private inside repository implementation and expose semantic refresh/load/load-more intents instead.',
        ),
      );

  static const _forbiddenParameterNames = <String>{
    'page',
    'pageIndex',
    'pageNumber',
    'pageSize',
    'page_size',
    'perPage',
    'per_page',
    'offset',
    'limit',
    'take',
    'cursor',
    'nextCursor',
    'lastId',
    'lastKey',
    'pageToken',
    'nextPageToken',
  };

  static final _forbiddenMethodNamePatterns = <RegExp>[
    RegExp(r'^hasMore[A-Z]'),
    RegExp(r'^loadNext.*Page$'),
  ];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isScheduleRepositoryContractFilePath(path)) {
      return;
    }

    context.registry.addMethodDeclaration((node) {
      final methodName = node.name.lexeme;
      final exposesPaginationState = _forbiddenMethodNamePatterns.any(
        (pattern) => pattern.hasMatch(methodName),
      );
      if (exposesPaginationState) {
        reporter.atNode(node, code);
      }

      final parameters = node.parameters?.parameters;
      if (parameters == null || parameters.isEmpty) {
        return;
      }

      for (final parameter in parameters) {
        final name = switch (parameter) {
          DefaultFormalParameter() => parameter.parameter.name?.lexeme,
          SimpleFormalParameter() => parameter.name?.lexeme,
          FieldFormalParameter() => parameter.name.lexeme,
          SuperFormalParameter() => parameter.name.lexeme,
          FunctionTypedFormalParameter() => parameter.name.lexeme,
          _ => null,
        };

        if (name == null || !_forbiddenParameterNames.contains(name)) {
          continue;
        }

        reporter.atNode(parameter, code);
      }
    });
  }
}
