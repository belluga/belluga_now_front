import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_match_cache_dto.dart';

class InviteContactImportCacheEntry {
  const InviteContactImportCacheEntry({
    required this.signature,
    required this.importedAt,
    this.matches = const <InviteContactMatchCacheDto>[],
  });

  final String signature;
  final DateTime importedAt;
  final List<InviteContactMatchCacheDto> matches;

  bool isFresh(DateTime now, Duration ttl) {
    final age = now.difference(importedAt);
    return !age.isNegative && age <= ttl;
  }
}
