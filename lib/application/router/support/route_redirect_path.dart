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
