import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

class PermissionHandlerImportForbiddenRule extends DartLintRule {
  PermissionHandlerImportForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'permission_handler_import_forbidden',
          problemMessage:
              'permission_handler is forbidden in this project because it collides with geolocator_apple during iOS archive.',
          correctionMessage:
              'Use flutter_contacts for contacts, firebase_messaging for notifications, and geolocator for location/settings. If you need to reintroduce permission_handler, first verify compatibility with every active native permission plugin and reopen approval.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null || !uri.startsWith('package:permission_handler/')) {
        return;
      }

      reporter.atNode(node.uri, code);
    });
  }
}
