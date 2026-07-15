import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'lint_code.dart';

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
