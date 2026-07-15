import 'package:analyzer/error/error.dart' as analyzer;

enum ErrorSeverity { info, warning, error }

class LintCode {
  const LintCode({
    required this.name,
    required this.problemMessage,
    this.correctionMessage,
    this.uniqueName,
    this.errorSeverity = ErrorSeverity.info,
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
      ErrorSeverity.info => analyzer.DiagnosticSeverity.INFO,
      ErrorSeverity.warning => analyzer.DiagnosticSeverity.WARNING,
      ErrorSeverity.error => analyzer.DiagnosticSeverity.ERROR,
    };
  }
}
