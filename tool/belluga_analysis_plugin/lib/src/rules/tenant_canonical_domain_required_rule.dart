// ignore_for_file: deprecated_member_use
import 'package:analyzer/dart/element/type.dart';

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../path_utils.dart';
import '../type_utils.dart';

class TenantCanonicalDomainRequiredRule extends DartLintRule {
  TenantCanonicalDomainRequiredRule()
      : super(
          code: const LintCode(
            errorSeverity: ErrorSeverity.WARNING,
            name: 'tenant_canonical_domain_required',
            problemMessage:
                'Tenant-scoped networking code must derive URLs from AppData.mainDomainValue after bootstrap.',
            correctionMessage:
                'Treatments: replace href/hostname/schema-based tenant URL composition with appData.mainDomainValue.value.',
          ),
        );

  static const _forbiddenAppDataProperties = {
    'href',
    'hostname',
    'schema',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!isTenantCanonicalDomainEnforcementFilePath(path)) {
      return;
    }

    context.registry.addPropertyAccess((node) {
      final targetType = node.target?.staticType;
      if (!_isForbiddenAppDataProperty(targetType, node.propertyName.name)) {
        return;
      }

      reporter.atNode(node.propertyName, code);
    });

    context.registry.addPrefixedIdentifier((node) {
      if (!_isForbiddenAppDataProperty(
        node.prefix.staticType,
        node.identifier.name,
      )) {
        return;
      }

      reporter.atNode(node.identifier, code);
    });
  }

  bool _isForbiddenAppDataProperty(DartType? targetType, String propertyName) {
    return dartTypeName(targetType) == 'AppData' &&
        _forbiddenAppDataProperties.contains(propertyName);
  }
}
