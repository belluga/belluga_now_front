final class TenantAdminEventsMediaPayloadNormalizer {
  const TenantAdminEventsMediaPayloadNormalizer();

  Object? normalize(
    Object? raw, {
    required Uri tenantOrigin,
  }) {
    if (raw is List) {
      return raw
          .map((entry) => normalize(entry, tenantOrigin: tenantOrigin))
          .toList(growable: false);
    }

    if (raw is! Map) {
      return raw;
    }

    return raw.map((key, value) {
      final normalizedKey = key.toString();
      if (_eventMediaUrlKeys.contains(normalizedKey) && value is String) {
        return MapEntry(
          normalizedKey,
          _normalizeEventMediaUrl(value, tenantOrigin),
        );
      }

      return MapEntry(
        normalizedKey,
        normalize(value, tenantOrigin: tenantOrigin),
      );
    });
  }

  String _normalizeEventMediaUrl(String rawUrl, Uri tenantOrigin) {
    final value = rawUrl.trim();
    if (value.isEmpty) {
      return value;
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null || parsed.host.trim().isNotEmpty) {
      return value;
    }

    if (parsed.path.startsWith('/')) {
      return tenantOrigin
          .resolve(parsed.path)
          .replace(
            query: parsed.hasQuery ? parsed.query : null,
            fragment: parsed.hasFragment ? parsed.fragment : null,
          )
          .toString();
    }

    return tenantOrigin.resolveUri(parsed).toString();
  }

  static const Set<String> _eventMediaUrlKeys = {
    'avatar_url',
    'cover_url',
    'logo_url',
    'hero_image_url',
  };
}
