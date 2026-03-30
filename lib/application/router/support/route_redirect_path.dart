import 'package:auto_route/auto_route.dart';

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
