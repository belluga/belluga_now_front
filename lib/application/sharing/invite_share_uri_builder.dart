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

  return resolvedOrigin
      .resolve('/invite')
      .replace(queryParameters: <String, String>{'code': normalizedCode});
}
