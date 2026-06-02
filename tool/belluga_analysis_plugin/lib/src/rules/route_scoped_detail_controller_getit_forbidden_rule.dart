// ignore_for_file: deprecated_member_use

import 'package:belluga_analysis_plugin/src/compat/custom_lint_compat.dart';

import '../getit_utils.dart';
import '../path_utils.dart';
import '../type_utils.dart';

class RouteScopedDetailControllerGetItForbiddenRule extends DartLintRule {
  RouteScopedDetailControllerGetItForbiddenRule()
    : super(
        code: const LintCode(
          errorSeverity: ErrorSeverity.WARNING,
          name: 'route_scoped_detail_controller_getit_forbidden',
          problemMessage:
              'Stackable tenant-public detail screens must resolve their detail controller from RouteInstanceScope, not global GetIt.',
          correctionMessage:
              'Use RouteInstanceScope.get<T>(context) so parent/child route instances and route-owned overlays keep isolated controller identity.',
        ),
      );

  static const _coveredControllerTypeNames = <String>{
    'AccountProfileDetailController',
    'ImmersiveEventDetailController',
    'StaticAssetDetailController',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final path = normalizePath(resolver.source.fullName);
    if (!_isCoveredDetailScreenPath(path)) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (!isGetItMethodInvocation(node)) {
        return;
      }

      final typeName = firstTypeArgumentName(node.typeArguments);
      if (!_coveredControllerTypeNames.contains(typeName)) {
        return;
      }

      reporter.atNode(node.methodName, code);
    });

    context.registry.addFunctionExpressionInvocation((node) {
      if (!isGetItCallableInvocation(node)) {
        return;
      }

      final typeName = firstTypeArgumentName(node.typeArguments);
      if (!_coveredControllerTypeNames.contains(typeName)) {
        return;
      }

      reporter.atNode(node.function, code);
    });
  }

  bool _isCoveredDetailScreenPath(String path) {
    return path.endsWith(
          '/lib/presentation/tenant_public/partners/account_profile_detail_screen.dart',
        ) ||
        path.endsWith(
          '/lib/presentation/tenant_public/static_assets/static_asset_detail_screen.dart',
        ) ||
        path.endsWith(
          '/lib/presentation/tenant_public/schedule/screens/immersive_event_detail/immersive_event_detail_screen.dart',
        ) ||
        path.endsWith(
          'lib/presentation/tenant_public/partners/account_profile_detail_screen.dart',
        ) ||
        path.endsWith(
          'lib/presentation/tenant_public/static_assets/static_asset_detail_screen.dart',
        ) ||
        path.endsWith(
          'lib/presentation/tenant_public/schedule/screens/immersive_event_detail/immersive_event_detail_screen.dart',
        );
  }
}
