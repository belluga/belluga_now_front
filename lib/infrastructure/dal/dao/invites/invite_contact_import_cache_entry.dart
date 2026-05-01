class InviteContactImportCacheEntry {
  const InviteContactImportCacheEntry({
    required this.signature,
    required this.importedAt,
  });

  final String signature;
  final DateTime importedAt;

  bool isFresh(DateTime now, Duration ttl) {
    final age = now.difference(importedAt);
    return !age.isNegative && age <= ttl;
  }
}
