import 'package:belluga_now/application/configurations/belluga_constants.dart';

String resolveTenantAdminBaseUrl(
  String selectedDomain, {
  String? landlordOriginOverride,
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
  final landlordUri =
      hasExplicitScheme ? null : _requireLandlordOrigin(landlordOriginOverride);
  final scheme = hasExplicitScheme
      ? _validateHttpScheme(parsed.scheme)
      : landlordUri!.scheme;
  final port = parsed.hasPort
      ? parsed.port
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
  final parsed = Uri.tryParse(landlordOrigin);
  if (parsed == null ||
      !parsed.hasScheme ||
      (parsed.scheme != 'http' && parsed.scheme != 'https') ||
      parsed.host.trim().isEmpty) {
    throw StateError(
      'Invalid LANDLORD_DOMAIN: "$landlordOrigin". '
      'Expected a full origin like http://host:port.',
    );
  }
  return parsed;
}
