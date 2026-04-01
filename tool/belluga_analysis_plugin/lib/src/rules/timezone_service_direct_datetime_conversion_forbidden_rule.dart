// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class TimezoneServiceDirectDateTimeConversionForbiddenRule
    extends DartLintRule {
  TimezoneServiceDirectDateTimeConversionForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'timezone_service_direct_datetime_conversion_forbidden',
          problemMessage:
              'Direct DateTime timezone conversion is forbidden outside TimezoneService/TimezoneConverter.',
          correctionMessage:
              'Use TimezoneConverter.utcToLocal/localToUtc (or TimezoneService) instead of calling DateTime.toLocal/toUtc directly.',
        ),
      );

  static const _allowedPaths = <String>{
    '/lib/application/time/timezone_converter.dart',
    '/lib/infrastructure/services/timezone/timezone_service.dart',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isLibFilePath(path) || isGeneratedFilePath(path)) {
      return;
    }
    if (_isAllowedPath(path)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (methodName != 'toLocal' && methodName != 'toUtc') {
        return;
      }

      final target = node.target;
      if (target == null) {
        return;
      }

      final typeName = target.staticType?.getDisplayString(
        withNullability: false,
      );
      if (typeName != 'DateTime') {
        return;
      }

      reporter.atNode(node.methodName, code);
    });
  }

  bool _isAllowedPath(String path) {
    for (final suffix in _allowedPaths) {
      if (path.endsWith(suffix)) {
        return true;
      }
    }
    return false;
  }
}
