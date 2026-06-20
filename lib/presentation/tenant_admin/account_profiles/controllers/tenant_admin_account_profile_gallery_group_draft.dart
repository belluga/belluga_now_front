import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_item_draft.dart';

class TenantAdminAccountProfileGalleryGroupDraft {
  TenantAdminAccountProfileGalleryGroupDraft({
    required this.groupId,
    required this.subtitle,
    required this.order,
    List<TenantAdminAccountProfileGalleryItemDraft>? items,
  }) : items = List<TenantAdminAccountProfileGalleryItemDraft>.unmodifiable(
          items ?? const <TenantAdminAccountProfileGalleryItemDraft>[],
        );

  factory TenantAdminAccountProfileGalleryGroupDraft.fromRead(
    TenantAdminAccountProfileGalleryGroup group,
  ) {
    return TenantAdminAccountProfileGalleryGroupDraft(
      groupId: group.groupId,
      subtitle: group.subtitle,
      order: group.order,
      items: group.items
          .map(TenantAdminAccountProfileGalleryItemDraft.fromRead)
          .toList(growable: false),
    );
  }

  final String groupId;
  final String subtitle;
  final int order;
  final List<TenantAdminAccountProfileGalleryItemDraft> items;

  TenantAdminAccountProfileGalleryGroupDraft copyWith({
    String? groupId,
    String? subtitle,
    int? order,
    List<TenantAdminAccountProfileGalleryItemDraft>? items,
  }) {
    return TenantAdminAccountProfileGalleryGroupDraft(
      groupId: groupId ?? this.groupId,
      subtitle: subtitle ?? this.subtitle,
      order: order ?? this.order,
      items: items ?? this.items,
    );
  }
}
