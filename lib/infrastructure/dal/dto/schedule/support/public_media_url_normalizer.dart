import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:get_it/get_it.dart';

String? normalizeTenantPublicMediaUrl(
  String? rawUrl, {
  Uri? tenantOrigin,
}) {
  final normalized = rawUrl?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  final parsed = Uri.tryParse(normalized);
  if (parsed == null) {
    return normalized;
  }

  if (parsed.host.trim().isNotEmpty) {
    return parsed.toString();
  }

  final resolvedTenantOrigin = tenantOrigin ?? _resolveTenantOrigin();
  if (resolvedTenantOrigin == null) {
    return null;
  }

  if (parsed.path.startsWith('/')) {
    final canonical = resolvedTenantOrigin.resolve(parsed.path);
    return canonical
        .replace(
          query: parsed.hasQuery ? parsed.query : null,
          fragment: parsed.hasFragment ? parsed.fragment : null,
        )
        .toString();
  }

  return resolvedTenantOrigin.resolveUri(parsed).toString();
}

Uri? _resolveTenantOrigin() {
  if (!GetIt.I.isRegistered<AppData>()) {
    return null;
  }

  final origin = GetIt.I.get<AppData>().mainDomainValue.value;
  if (origin.host.trim().isEmpty) {
    return null;
  }

  return origin.replace(path: '/', query: null, fragment: null);
}
