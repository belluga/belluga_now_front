import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:get_it/get_it.dart';

const String webPromotionRoutePath = '/baixe-o-app';

String buildRedirectPathFromRouteMatch(RouteMatch route) {
  return buildRedirectPath(
    fullPath: route.fullPath,
    queryParams: route.queryParams.rawMap,
  );
}

String buildRedirectPath({
  required String fullPath,
  required Map<String, dynamic> queryParams,
}) {
  final rawPath = fullPath.trim();
  final normalizedPath = rawPath.isEmpty
      ? '/'
      : rawPath.startsWith('/')
          ? rawPath
          : '/$rawPath';
  final normalizedParams = queryParams.isEmpty
      ? null
      : queryParams.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
  return Uri(path: normalizedPath, queryParameters: normalizedParams)
      .toString();
}

String resolveWebPromotionPath({
  required String redirectPath,
}) {
  final shareCode = resolveWebPromotionShareCode(redirectPath: redirectPath);
  if (shareCode == null) {
    return '/';
  }

  return Uri(
    path: '/invite',
    queryParameters: <String, String>{'code': shareCode},
  ).toString();
}

String? resolveWebPromotionShareCode({
  required String redirectPath,
}) {
  final raw = redirectPath.trim();
  if (raw.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(raw);
  if (uri == null) {
    return null;
  }

  final normalizedPath = _normalizePath(uri.path);
  final isInviteContext =
      normalizedPath == '/invite' || normalizedPath == '/convites';
  if (!isInviteContext) {
    return null;
  }

  final code = uri.queryParameters['code']?.trim();
  if (code == null || code.isEmpty) {
    return null;
  }

  return code;
}

String buildWebPromotionBoundaryPath({
  required String redirectPath,
}) {
  final normalizedRedirectPath = redirectPath.trim();
  final resolvedRedirectPath =
      normalizedRedirectPath.isEmpty ? '/' : normalizedRedirectPath;
  return Uri(
    path: webPromotionRoutePath,
    queryParameters: <String, String>{
      'redirect': resolvedRedirectPath,
    },
  ).toString();
}

Uri? buildTenantPromotionUriFromAppContext({
  String? redirectPath,
  String? shareCode,
  String? platformTarget,
  Uri? mainDomainUri,
}) {
  final normalizedRedirectPath = redirectPath?.trim();
  final hasRedirectPath =
      normalizedRedirectPath != null && normalizedRedirectPath.isNotEmpty;
  final redirectContextCode = hasRedirectPath
      ? resolveWebPromotionShareCode(
          redirectPath: normalizedRedirectPath,
        )
      : null;
  final trimmedCode = shareCode?.trim();
  final normalizedShareCode =
      (trimmedCode == null || trimmedCode.isEmpty) ? null : trimmedCode;
  final normalizedCode =
      redirectContextCode ?? (hasRedirectPath ? null : normalizedShareCode);
  final normalizedPlatformTarget =
      _normalizePromotionPlatformTarget(platformTarget);
  final targetPath = normalizedCode == null ? '/' : '/invite';

  final resolvedBaseUri = mainDomainUri ??
      (GetIt.I.isRegistered<AppDataRepositoryContract>()
          ? GetIt.I
              .get<AppDataRepositoryContract>()
              .appData
              .mainDomainValue
              .value
          : Uri.tryParse(Uri.base.origin));
  if (resolvedBaseUri == null || resolvedBaseUri.host.trim().isEmpty) {
    return null;
  }

  final targetUri = resolvedBaseUri.resolve('/open-app');
  final query = <String, String>{
    'path': targetPath,
    'store_channel': 'web',
    if (normalizedCode != null) 'code': normalizedCode,
    if (normalizedPlatformTarget != null)
      'platform_target': normalizedPlatformTarget,
  };
  return targetUri.replace(
    queryParameters: query.isEmpty ? null : query,
  );
}

String _normalizePath(String path) {
  final raw = path.trim();
  if (raw.isEmpty) {
    return '/';
  }

  var normalized = raw.startsWith('/') ? raw : '/$raw';
  if (normalized.length > 1 && normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

String? _normalizePromotionPlatformTarget(String? platformTarget) {
  final normalized = platformTarget?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  if (normalized == 'android' || normalized == 'ios') {
    return normalized;
  }
  return null;
}
