// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class LocationOriginCanonicalStreamSubscriptionRequiredRule
    extends DartLintRule {
  LocationOriginCanonicalStreamSubscriptionRequiredRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'location_origin_canonical_stream_subscription_required',
          problemMessage:
              'Geo refresh workflows must not subscribe directly to raw user-location streams.',
          correctionMessage:
              'Treatments: subscribe to LocationOriginService.effectiveOriginStreamValue for canonical origin changes; reserve raw user-location stream listeners for the canonical origin service itself.',
        ),
      );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!_isTargetPath(path) || _isAllowlistedPath(path)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'listen') {
        return;
      }

      final target = node.target;
      if (target == null) {
        return;
      }

      final targetText = target.toString();
      if (targetText.endsWith('userLocationStreamValue.stream') ||
          targetText.endsWith('lastKnownLocationStreamValue.stream') ||
          targetText.endsWith('lastKnownCapturedAtStreamValue.stream')) {
        reporter.atNode(node.methodName, code);
      }
    });
  }

  bool _isTargetPath(String path) {
    final normalized = normalizePath(path);
    return isPresentationControllerFilePath(normalized) ||
        isRepositoryFilePath(normalized) ||
        normalized.contains('/lib/infrastructure/dal/dao/');
  }

  bool _isAllowlistedPath(String path) {
    final normalized = normalizePath(path);
    return normalized.endsWith(
      '/lib/infrastructure/services/location_origin_service.dart',
    );
  }
}
