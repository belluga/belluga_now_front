import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:get_it/get_it.dart';

const String webPromotionRoutePath = '/baixe-o-app';
const int _maxPromotionRedirectUnwrapDepth = 5;
const int _maxPromotionRedirectPathLength = 2048;

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
  if (shareCode != null) {
    return Uri(
      path: '/invite',
      queryParameters: <String, String>{'code': shareCode},
    ).toString();
  }

  return _resolveAllowedPromotionRedirectPath(
        redirectPath: redirectPath,
        includeAuthOwnedAppPaths: false,
      ) ??
      '/';
}

String resolveWebPromotionDismissPath({
  required String redirectPath,
}) {
  if (isAuthOwnedPromotionRedirectPath(redirectPath)) {
    return '/';
  }

  return resolveWebPromotionPath(
    redirectPath: redirectPath,
  );
}

String? resolveWebPromotionShareCode({
  required String redirectPath,
}) {
  final raw = redirectPath.trim();
  if (raw.isEmpty || raw.length > _maxPromotionRedirectPathLength) {
    return null;
  }

  final uri = Uri.tryParse(raw);
  if (uri == null || _isExternalPromotionRedirectUri(uri, raw)) {
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

bool isAuthOwnedPromotionRedirectPath(String? rawRedirectPath) {
  final normalized = _normalizePath(
    Uri.tryParse(rawRedirectPath?.trim() ?? '')?.path ?? rawRedirectPath ?? '',
  );

  if (normalized == '/profile') {
    return true;
  }

  if (normalized == '/convites/compartilhar') {
    return true;
  }

  if (normalized == '/workspace' || normalized.startsWith('/workspace/')) {
    return true;
  }

  if (normalized == '/auth' || normalized.startsWith('/auth/')) {
    return true;
  }

  return false;
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
  final targetPath = normalizedCode == null
      ? _resolveAllowedPromotionRedirectPath(
            redirectPath: normalizedRedirectPath,
            includeAuthOwnedAppPaths: true,
          ) ??
          '/'
      : '/invite';

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

String? _resolveAllowedPromotionRedirectPath({
  required String? redirectPath,
  required bool includeAuthOwnedAppPaths,
  int unwrapDepth = 0,
}) {
  final raw = redirectPath?.trim();
  if (raw == null ||
      raw.isEmpty ||
      raw.length > _maxPromotionRedirectPathLength) {
    return null;
  }

  final uri = Uri.tryParse(raw);
  if (uri == null || _isExternalPromotionRedirectUri(uri, raw)) {
    return null;
  }

  final normalizedPath = _normalizePath(uri.path);
  if (normalizedPath == webPromotionRoutePath) {
    return null;
  }

  if (normalizedPath == '/auth' || normalizedPath.startsWith('/auth/')) {
    if (unwrapDepth >= _maxPromotionRedirectUnwrapDepth) {
      return null;
    }
    final nestedRedirect = uri.queryParameters['redirect'];
    if (nestedRedirect == null || nestedRedirect.trim().isEmpty) {
      return null;
    }
    return _resolveAllowedPromotionRedirectPath(
      redirectPath: nestedRedirect,
      includeAuthOwnedAppPaths: includeAuthOwnedAppPaths,
      unwrapDepth: unwrapDepth + 1,
    );
  }

  final shareCode = resolveWebPromotionShareCode(redirectPath: raw);
  if (shareCode != null) {
    return Uri(
      path: '/invite',
      queryParameters: <String, String>{'code': shareCode},
    ).toString();
  }

  if (normalizedPath == '/invite' || normalizedPath == '/convites') {
    return null;
  }

  if (isAuthOwnedPromotionRedirectPath(normalizedPath)) {
    if (!includeAuthOwnedAppPaths ||
        !_isAllowedAuthOwnedAppContinuationPath(normalizedPath)) {
      return null;
    }
    return Uri(path: normalizedPath).toString();
  }

  if (!_isAllowedPublicPromotionContinuationPath(normalizedPath)) {
    return null;
  }

  return Uri(
    path: normalizedPath,
    queryParameters: _allowedQueryParametersForPath(normalizedPath, uri),
  ).toString();
}

bool _isAllowedPublicPromotionContinuationPath(String normalizedPath) {
  if (normalizedPath == '/' ||
      normalizedPath == '/privacy-policy' ||
      normalizedPath == '/descobrir' ||
      normalizedPath == '/mapa' ||
      normalizedPath == '/mapa/poi' ||
      normalizedPath == '/location/permission') {
    return true;
  }

  if (_isEventDetailPath(normalizedPath)) {
    return true;
  }

  final segments = _pathSegments(normalizedPath);
  if (segments.length != 2) {
    return false;
  }

  final prefix = segments.first;
  return prefix == 'parceiro' || prefix == 'static';
}

bool _isExternalPromotionRedirectUri(Uri uri, String raw) {
  return uri.hasScheme || uri.hasAuthority || raw.startsWith('//');
}

bool _isAllowedAuthOwnedAppContinuationPath(String normalizedPath) {
  return normalizedPath == '/profile' ||
      normalizedPath == '/convites/compartilhar';
}

Map<String, String>? _allowedQueryParametersForPath(
  String normalizedPath,
  Uri uri,
) {
  final allowedKeys = <String>{
    if (_isEventDetailPath(normalizedPath)) 'occurrence',
    if (normalizedPath == '/mapa' || normalizedPath == '/mapa/poi') ...{
      'poi',
      'stack',
    },
  };
  if (allowedKeys.isEmpty) {
    return null;
  }

  final result = <String, String>{};
  for (final key in allowedKeys) {
    final value = uri.queryParameters[key]?.trim();
    if (value != null && value.isNotEmpty) {
      result[key] = value;
    }
  }
  return result.isEmpty ? null : result;
}

bool _isEventDetailPath(String normalizedPath) {
  final segments = _pathSegments(normalizedPath);
  return segments.length == 3 &&
      segments[0] == 'agenda' &&
      segments[1] == 'evento' &&
      segments[2].trim().isNotEmpty;
}

List<String> _pathSegments(String normalizedPath) {
  return normalizedPath
      .split('/')
      .where((segment) => segment.trim().isNotEmpty)
      .toList(growable: false);
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
