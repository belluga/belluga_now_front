import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/error/error.dart' as analyzer;

import 'custom_lint_context.dart';
import 'custom_lint_resolver.dart';
import 'custom_lint_source.dart';
import 'error_reporter.dart';
import 'lint_code.dart';
import 'lint_rule_node_registry.dart';

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
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final resolver = CustomLintResolver(
      source: CustomLintSource(context.definingUnit.file.path),
    );
    final reporter = ErrorReporter(this);
    final lintContext = CustomLintContext(LintRuleNodeRegistry(this, registry));

    run(resolver, reporter, lintContext);
  }
}
