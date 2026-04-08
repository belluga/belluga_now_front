// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class DomainPagedResultTypeForbiddenRule extends DartLintRule {
  DomainPagedResultTypeForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'domain_paged_result_type_forbidden',
          problemMessage:
              'Public domain paged-result/envelope types are forbidden.',
          correctionMessage:
              'Treatments: keep pagination helpers private inside repository implementations and expose materialized domain items or aggregate-specific semantic methods only.',
        ),
      );

  static final _forbiddenNamePatterns = <RegExp>[
    RegExp(r'^Paged[A-Z].*'),
    RegExp(r'.*PageResult$'),
    RegExp(r'.*PaginationResult$'),
    RegExp(r'.*PageEnvelope$'),
    RegExp(r'.*CacheSnapshot$'),
  ];

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isDomainScheduleFilePath(path)) {
      return;
    }

    context.registry.addClassDeclaration((node) {
      if (_matchesForbiddenPagedName(node.name.lexeme)) {
        reporter.atNode(node, code);
      }
    });
  }

  bool _matchesForbiddenPagedName(String name) {
    for (final pattern in _forbiddenNamePatterns) {
      if (pattern.hasMatch(name)) {
        return true;
      }
    }
    return false;
  }
}
