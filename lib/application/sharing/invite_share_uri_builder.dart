import 'package:belluga_now/application/router/support/tenant_public_event_path.dart';

Uri? buildInviteShareUri({
  required String? origin,
  required String? shareCode,
  String? eventSlug,
  String? occurrenceId,
}) {
  final resolvedOrigin = Uri.tryParse(origin?.trim() ?? '');
  final normalizedCode = shareCode?.trim();
  if (resolvedOrigin == null ||
      resolvedOrigin.host.trim().isEmpty ||
      normalizedCode == null ||
      normalizedCode.isEmpty) {
    return null;
  }

  final fallbackPath = buildTenantPublicEventPath(
    eventSlug: eventSlug,
    occurrenceId: occurrenceId,
  );

  return resolvedOrigin.resolve('/invite').replace(
        queryParameters: <String, String>{
          'code': normalizedCode,
          if (fallbackPath != null && fallbackPath.isNotEmpty)
            'fallback': fallbackPath,
        },
      );
}
