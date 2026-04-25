import 'package:belluga_now/application/tenant_admin/settings/tenant_admin_legacy_map_filter_canonicalizer.dart';

class TenantAdminDiscoveryFiltersSettingsCanonicalizer {
  const TenantAdminDiscoveryFiltersSettingsCanonicalizer();

  static const List<String> canonicalSurfaceKeys = <String>[
    'public_map.primary',
    'home.events',
    'discovery.account_profiles',
  ];

  Map<String, dynamic> canonicalize({
    required Map<String, dynamic> discoveryFilters,
    Map<String, dynamic>? legacyMapUi,
  }) {
    final next = _normalizeSurfaces(discoveryFilters);
    final surfaces = _mutableMap(next['surfaces']);
    final mapSurface = _mutableMap(surfaces['public_map.primary']);
    final rawMapFilters = mapSurface['filters'];
    final hasCanonicalMapFilters =
        rawMapFilters is Iterable && rawMapFilters.isNotEmpty;
    final legacyFilters = legacyMapUi?['filters'];
    if (!hasCanonicalMapFilters && legacyFilters is Iterable) {
      mapSurface['target'] = 'map_poi';
      mapSurface['primary_selection_mode'] = 'single';
      mapSurface['filters'] = legacyFilters
          .map(const TenantAdminLegacyMapFilterCanonicalizer().canonicalize)
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      surfaces['public_map.primary'] = mapSurface;
      next['surfaces'] = surfaces;
    }
    return next;
  }

  Map<String, dynamic> _normalizeSurfaces(
    Map<String, dynamic> discoveryFilters,
  ) {
    final next = Map<String, dynamic>.from(discoveryFilters);
    final surfaces = _mutableMap(next['surfaces']);

    for (final surfaceKey in canonicalSurfaceKeys) {
      final nestedSurface = _surfaceFromNestedPath(surfaces, surfaceKey);
      if (nestedSurface.isNotEmpty && surfaces[surfaceKey] == null) {
        surfaces[surfaceKey] = nestedSurface;
      }
    }

    for (final entry in discoveryFilters.entries) {
      final rawKey = entry.key.trim();
      if (!rawKey.startsWith('surfaces.')) {
        continue;
      }
      for (final surfaceKey in canonicalSurfaceKeys) {
        final prefix = 'surfaces.$surfaceKey.';
        if (!rawKey.startsWith(prefix)) {
          continue;
        }
        final surface = _mutableMap(surfaces[surfaceKey]);
        _setDottedPath(
          surface,
          rawKey.substring(prefix.length),
          entry.value,
        );
        surfaces[surfaceKey] = surface;
        break;
      }
    }

    if (surfaces.isNotEmpty) {
      next['surfaces'] = surfaces;
    }
    return next;
  }

  Map<String, dynamic> _surfaceFromNestedPath(
    Map<String, dynamic> surfaces,
    String surfaceKey,
  ) {
    final segments = surfaceKey.split('.');
    Object? cursor = surfaces;
    for (final segment in segments) {
      final map = _mutableMap(cursor);
      if (map.isEmpty || !map.containsKey(segment)) {
        return const <String, dynamic>{};
      }
      cursor = map[segment];
    }
    return _mutableMap(cursor);
  }

  void _setDottedPath(
    Map<String, dynamic> target,
    String path,
    Object? value,
  ) {
    final segments = path
        .split('.')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) {
      return;
    }
    var cursor = target;
    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      if (index == segments.length - 1) {
        cursor[segment] = value;
        return;
      }
      final next = cursor[segment];
      if (next is Map<String, dynamic>) {
        cursor = next;
        continue;
      }
      if (next is Map) {
        final normalized = Map<String, dynamic>.from(next);
        cursor[segment] = normalized;
        cursor = normalized;
        continue;
      }
      final created = <String, dynamic>{};
      cursor[segment] = created;
      cursor = created;
    }
  }

  Map<String, dynamic> _mutableMap(Object? raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }
}
