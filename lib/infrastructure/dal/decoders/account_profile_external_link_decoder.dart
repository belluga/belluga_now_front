import 'package:belluga_now/domain/partners/account_profile_external_link.dart';

abstract final class AccountProfileExternalLinkDecoder {
  static List<AccountProfileExternalLink> decodeList(
    Object? value, {
    int? limit,
  }) {
    if (value is! List) return const [];
    // The transport ceiling is structural, not a plan or authoring policy:
    // the closed registry can contain at most one item for each known type.
    // Admin detail additionally supplies the backend-resolved plan capacity;
    // public projection intentionally omits that capacity and relies on the
    // normalized backend projection. No client-owned numeric limit is used.
    final structuralCeiling = AccountProfileExternalLinkType.values.length;
    final admissibleLength = limit == null || limit > structuralCeiling
        ? structuralCeiling
        : limit;
    if (admissibleLength < 0 || value.length > admissibleLength) {
      return const [];
    }

    final decoded =
        <({AccountProfileExternalLinkType type, String id, Map raw})>[];
    for (final item in value) {
      if (item is! Map || item['type'] is! String || item['id'] is! String) {
        continue;
      }
      try {
        decoded.add((
          type: AccountProfileExternalLinkTypeValue(
            item['type'] as String,
          ).value,
          id: (item['id'] as String).trim(),
          raw: item,
        ));
      } on Object {
        // Transport payloads are untrusted and fail closed per item.
      }
    }

    final typeCounts = <AccountProfileExternalLinkType, int>{};
    final idCounts = <String, int>{};
    for (final item in decoded) {
      typeCounts[item.type] = (typeCounts[item.type] ?? 0) + 1;
      if (item.id.isNotEmpty) idCounts[item.id] = (idCounts[item.id] ?? 0) + 1;
    }

    final resolved =
        <AccountProfileExternalLinkType, AccountProfileExternalLink>{};
    for (final item in decoded) {
      final rawUrl = item.raw['url'];
      if (rawUrl is! String ||
          typeCounts[item.type] != 1 ||
          idCounts[item.id] != 1 ||
          (item.type != AccountProfileExternalLinkType.website &&
              item.raw.containsKey('label')) ||
          (item.type == AccountProfileExternalLinkType.website &&
              item.raw['label'] is! String)) {
        continue;
      }
      try {
        final rawLabel = item.raw['label'];
        resolved[item.type] =
            AccountProfileExternalLinkRegistry.validateMutation(
              id: AccountProfileExternalLinkIdValue(item.id),
              type: item.type,
              url: AccountProfileExternalLinkUrlValue(rawUrl),
              label: rawLabel is String
                  ? AccountProfileExternalLinkLabelValue(rawLabel)
                  : null,
            );
      } on Object {
        // Invalid or ambiguous values remain absent from the domain projection.
      }
    }

    final ordered = AccountProfileExternalLinkType.values
        .map((type) => resolved[type])
        .whereType<AccountProfileExternalLink>()
        .toList(growable: false);
    if (limit == null) return ordered;
    return ordered.take(limit).toList(growable: false);
  }
}
