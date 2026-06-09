String? buildTenantPublicEventPath({
  required String? eventSlug,
  String? occurrenceId,
}) {
  final normalizedSlug = eventSlug?.trim();
  if (normalizedSlug == null || normalizedSlug.isEmpty) {
    return null;
  }

  final normalizedOccurrenceId = occurrenceId?.trim();
  return Uri(
    path: '/agenda/evento/$normalizedSlug',
    queryParameters:
        normalizedOccurrenceId == null || normalizedOccurrenceId.isEmpty
            ? null
            : <String, String>{'occurrence': normalizedOccurrenceId},
  ).toString();
}
