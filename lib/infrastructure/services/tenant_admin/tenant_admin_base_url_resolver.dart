import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:flutter/foundation.dart';

String resolveTenantAdminBaseUrl(
  String selectedDomain, {
  String? landlordOriginOverride,
  String? browserOriginOverride,
}) {
  final normalized = selectedDomain.trim();
  if (normalized.isEmpty) {
    throw StateError('Tenant admin scope is not selected.');
  }

  final parsed = Uri.tryParse(
    normalized.contains('://') ? normalized : 'https://$normalized',
  );
  if (parsed == null || parsed.host.trim().isEmpty) {
    throw StateError('Invalid tenant domain selected for admin scope.');
  }

  final hasExplicitScheme = normalized.contains('://');
  final browserUri =
      hasExplicitScheme ? null : _resolveBrowserOrigin(browserOriginOverride);
  final landlordUri = hasExplicitScheme
      ? null
      : (browserUri == null
          ? _requireLandlordOrigin(landlordOriginOverride)
          : null);
  final scheme = hasExplicitScheme
      ? _validateHttpScheme(parsed.scheme)
      : browserUri?.scheme ?? landlordUri!.scheme;
  final port = parsed.hasPort
      ? parsed.port
      : (browserUri?.hasPort ?? false)
          ? browserUri!.port
          : (landlordUri?.hasPort ?? false)
              ? landlordUri!.port
              : null;

  final origin = Uri(
    scheme: scheme,
    host: parsed.host,
    port: port,
  );

  return origin.resolve('/admin/api').toString();
}

Uri? _resolveBrowserOrigin(String? browserOriginOverride) {
  final raw = browserOriginOverride?.trim();
  if (raw != null && raw.isNotEmpty) {
    return _parseOrigin(raw, fieldName: 'browser origin override');
  }
  if (!kIsWeb) {
    return null;
  }
  return _parseOrigin(Uri.base.toString(), fieldName: 'current browser origin');
}

Uri _parseOrigin(
  String raw, {
  required String fieldName,
}) {
  final parsed = Uri.tryParse(raw);
  if (parsed == null ||
      !parsed.hasScheme ||
      (parsed.scheme != 'http' && parsed.scheme != 'https') ||
      parsed.host.trim().isEmpty) {
    throw StateError(
      'Invalid $fieldName: "$raw". Expected a full origin like http://host:port.',
    );
  }
  return Uri(
    scheme: parsed.scheme,
    host: parsed.host,
    port: parsed.hasPort ? parsed.port : null,
  );
}

String _validateHttpScheme(String scheme) {
  if (scheme == 'http' || scheme == 'https') {
    return scheme;
  }
  throw StateError(
    'Invalid tenant domain scheme "$scheme" for admin scope. '
    'Use http:// or https://.',
  );
}

Uri _requireLandlordOrigin(String? landlordOriginOverride) {
  final landlordOrigin =
      (landlordOriginOverride ?? BellugaConstants.landlordDomain).trim();
  if (landlordOrigin.isEmpty) {
    throw StateError(
      'LANDLORD_DOMAIN is required to resolve tenant admin base URL when '
      'tenant domain has no scheme.',
    );
  }
  return _parseOrigin(
    landlordOrigin,
    fieldName: 'LANDLORD_DOMAIN',
  );
}
