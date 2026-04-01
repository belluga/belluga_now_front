// ignore_for_file: deprecated_member_use

import 'package:analyzer/dart/ast/ast.dart';
import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';

class LocationOriginCanonicalResolutionRequiredRule extends DartLintRule {
  LocationOriginCanonicalResolutionRequiredRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'location_origin_canonical_resolution_required',
          problemMessage:
              'Geo consumers must not resolve canonical location origin inline.',
          correctionMessage:
              'Treatments: use the canonical LocationOrigin service/policy result; do not branch directly on tenantDefaultOrigin or construct LocationOrigin settings/reasons inline outside the canonical files.',
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

    context.registry.addPropertyAccess((node) {
      final propertyName = node.propertyName.name;
      if (propertyName == 'tenantDefaultOrigin') {
        reporter.atNode(node.propertyName, code);
        return;
      }

      final target = node.target;
      if (target == null) {
        return;
      }

      if (_looksLikeLocationOriginReasonTarget(target) ||
          _looksLikeLocationOriginSettingsTarget(target)) {
        reporter.atNode(node.propertyName, code);
      }
    });

    context.registry.addPrefixedIdentifier((node) {
      if (node.identifier.name == 'tenantDefaultOrigin') {
        reporter.atNode(node.identifier, code);
        return;
      }

      if (_looksLikeLocationOriginReasonPrefix(node.prefix) ||
          _looksLikeLocationOriginSettingsPrefix(node.prefix)) {
        reporter.atNode(node.identifier, code);
      }
    });

    context.registry.addInstanceCreationExpression((node) {
      final constructor = node.constructorName;
      final typeName = constructor.type.name.toString();
      if (typeName != 'LocationOriginSettings') {
        return;
      }
      reporter.atNode(constructor, code);
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
        ) ||
        normalized.endsWith(
          '/lib/presentation/shared/location_permission/location_origin_message_resolver.dart',
        ) ||
        normalized.endsWith(
          '/lib/infrastructure/repositories/app_data_repository.dart',
        ) ||
        normalized.endsWith(
          '/lib/domain/repositories/app_data_repository_contract.dart',
        );
  }

  bool _looksLikeLocationOriginReasonTarget(Expression target) {
    return target.toString() == 'LocationOriginReason';
  }

  bool _looksLikeLocationOriginSettingsTarget(Expression target) {
    return target.toString() == 'LocationOriginSettings';
  }

  bool _looksLikeLocationOriginReasonPrefix(Identifier prefix) {
    return prefix.name == 'LocationOriginReason';
  }

  bool _looksLikeLocationOriginSettingsPrefix(Identifier prefix) {
    return prefix.name == 'LocationOriginSettings';
  }
}
