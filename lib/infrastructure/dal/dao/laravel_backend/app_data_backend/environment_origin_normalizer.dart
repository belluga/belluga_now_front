Map<String, dynamic> normalizeEnvironmentOrigins(
  Map<String, dynamic> payload, {
  required String bootstrapBaseUrl,
}) {
  final bootstrapUri = Uri.tryParse(bootstrapBaseUrl.trim());
  if (!_isValidHttpOrigin(bootstrapUri)) {
    return Map<String, dynamic>.from(payload);
  }

  final normalized = Map<String, dynamic>.from(payload);
  final mainDomain = normalized['main_domain'];
  if (mainDomain is String) {
    normalized['main_domain'] = _normalizeDomainEntry(
      mainDomain,
      bootstrapUri!,
    );
  }

  final domains = normalized['domains'];
  if (domains is List) {
    normalized['domains'] = domains.map((entry) {
      if (entry is! String) {
        return entry;
      }
      return _normalizeDomainEntry(entry, bootstrapUri!);
    }).toList(growable: false);
  }

  return normalized;
}

String _normalizeDomainEntry(String raw, Uri bootstrapUri) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return raw;
  }

  final candidate =
      trimmed.contains('://') ? trimmed : '${bootstrapUri.scheme}://$trimmed';
  final parsed = Uri.tryParse(candidate);
  if (parsed == null || parsed.host.trim().isEmpty) {
    return raw;
  }

  if (!_isCompatibleDomainFamily(parsed.host, bootstrapUri.host)) {
    return trimmed;
  }

  final normalized = parsed.replace(
    scheme: bootstrapUri.scheme,
    port: parsed.hasPort
        ? parsed.port
        : bootstrapUri.hasPort
            ? bootstrapUri.port
            : null,
    query: null,
    fragment: null,
  );
  return _trimTrailingSlash(normalized.toString());
}

bool _isValidHttpOrigin(Uri? uri) {
  if (uri == null) {
    return false;
  }
  if (!uri.hasScheme || uri.host.trim().isEmpty) {
    return false;
  }
  return uri.scheme == 'http' || uri.scheme == 'https';
}

bool _isCompatibleDomainFamily(String targetHost, String bootstrapHost) {
  final normalizedTarget = targetHost.trim().toLowerCase();
  final normalizedBootstrap = bootstrapHost.trim().toLowerCase();
  if (normalizedTarget.isEmpty || normalizedBootstrap.isEmpty) {
    return false;
  }
  if (normalizedTarget == normalizedBootstrap) {
    return true;
  }
  return normalizedTarget.endsWith('.$normalizedBootstrap');
}

String _trimTrailingSlash(String value) {
  return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
