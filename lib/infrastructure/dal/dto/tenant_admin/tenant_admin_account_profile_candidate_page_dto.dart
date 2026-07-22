import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_candidate_item_dto.dart';

class TenantAdminAccountProfileCandidatePageDTO {
  const TenantAdminAccountProfileCandidatePageDTO({
    required this.items,
    required this.page,
    required this.perPage,
    required this.hasMore,
    required this.browseLimitReached,
  });

  final List<TenantAdminAccountProfileCandidateDTO> items;
  final int page;
  final int perPage;
  final bool hasMore;
  final bool browseLimitReached;

  factory TenantAdminAccountProfileCandidatePageDTO.fromJson(
    Map<String, dynamic> json,
  ) {
    final items = <TenantAdminAccountProfileCandidateDTO>[];
    final rawItems = json['data'];
    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is Map) {
          items.add(
            TenantAdminAccountProfileCandidateDTO.fromJson(
              Map<String, dynamic>.from(rawItem),
            ),
          );
        }
      }
    }

    return TenantAdminAccountProfileCandidatePageDTO(
      items: items,
      page: _toInt(json['page']),
      perPage: _toInt(json['per_page']),
      hasMore: json['has_more'] == true,
      browseLimitReached: json['browse_limit_reached'] == true,
    );
  }

  TenantAdminAccountProfileCandidatePage toDomain() {
    return TenantAdminAccountProfileCandidatePage(
      items: items.map((item) => item.toDomain()).toList(growable: false),
      pageValue: TenantAdminCountValue(page),
      perPageValue: TenantAdminCountValue(perPage),
      hasMoreValue: TenantAdminFlagValue(hasMore),
      browseLimitReachedValue: TenantAdminFlagValue(browseLimitReached),
    );
  }

  static int _toInt(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
