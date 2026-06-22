import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_group_draft.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_gallery_item_draft.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class TenantAdminAccountProfileGalleryOperations {
  const TenantAdminAccountProfileGalleryOperations._();

  static const int maxGroups = 6;
  static const int maxItems = 12;

  static List<TenantAdminAccountProfileGalleryGroupDraft> appendGroup(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups,
  ) {
    return normalizeGroupOrders([
      ...groups,
      TenantAdminAccountProfileGalleryGroupDraft(
        groupId: _nextGroupId(groups),
        subtitle: '',
        order: groups.length,
      ),
    ]);
  }

  static List<TenantAdminAccountProfileGalleryGroupDraft> renameGroup(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups, {
    required String groupId,
    required String subtitle,
  }) {
    return groups
        .map(
          (group) => group.groupId == groupId
              ? group.copyWith(subtitle: subtitle)
              : group,
        )
        .toList(growable: false);
  }

  static List<TenantAdminAccountProfileGalleryGroupDraft> removeGroup(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups, {
    required String groupId,
  }) {
    return normalizeGroupOrders(
      groups.where((group) => group.groupId != groupId).toList(growable: false),
    );
  }

  static List<TenantAdminAccountProfileGalleryGroupDraft> moveGroup(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups, {
    required String groupId,
    required int delta,
  }) {
    final next = [...groups]..sort((left, right) => left.order.compareTo(right.order));
    final index = next.indexWhere((group) => group.groupId == groupId);
    if (index < 0) {
      return groups;
    }
    final target = (index + delta).clamp(0, next.length - 1);
    if (target == index) {
      return groups;
    }
    final group = next.removeAt(index);
    next.insert(target, group);
    return normalizeGroupOrders(next);
  }

  static List<TenantAdminAccountProfileGalleryGroupDraft> appendItem(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups, {
    required String groupId,
    required XFile uploadFile,
    required VoidCallback onLimit,
  }) {
    if (totalItemCount(groups) >= maxItems) {
      onLimit();
      return groups;
    }
    return groups.map((group) {
      if (group.groupId != groupId) {
        return group;
      }
      final items = normalizeItemOrders([
        ...group.items,
        TenantAdminAccountProfileGalleryItemDraft(
          itemId: _nextItemId(groups),
          description: null,
          order: group.items.length,
          uploadFile: uploadFile,
        ),
      ]);
      return group.copyWith(items: items);
    }).toList(growable: false);
  }

  static List<TenantAdminAccountProfileGalleryGroupDraft> replaceItemUpload(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups, {
    required String groupId,
    required String itemId,
    required XFile uploadFile,
  }) {
    return groups.map((group) {
      if (group.groupId != groupId) {
        return group;
      }
      return group.copyWith(
        items: group.items
            .map(
              (item) => item.itemId == itemId
                  ? item.copyWith(uploadFile: uploadFile)
                  : item,
            )
            .toList(growable: false),
      );
    }).toList(growable: false);
  }

  static List<TenantAdminAccountProfileGalleryGroupDraft> updateItemDescription(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups, {
    required String groupId,
    required String itemId,
    required String description,
  }) {
    return groups.map((group) {
      if (group.groupId != groupId) {
        return group;
      }
      return group.copyWith(
        items: group.items
            .map(
              (item) => item.itemId == itemId
                  ? item.copyWith(
                      description: description.trim().isEmpty
                          ? null
                          : description,
                    )
                  : item,
            )
            .toList(growable: false),
      );
    }).toList(growable: false);
  }

  static List<TenantAdminAccountProfileGalleryGroupDraft> removeItem(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups, {
    required String groupId,
    required String itemId,
  }) {
    return groups.map((group) {
      if (group.groupId != groupId) {
        return group;
      }
      return group.copyWith(
        items: normalizeItemOrders(
          group.items
              .where((item) => item.itemId != itemId)
              .toList(growable: false),
        ),
      );
    }).toList(growable: false);
  }

  static List<TenantAdminAccountProfileGalleryGroupDraft> moveItem(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups, {
    required String groupId,
    required String itemId,
    required int delta,
  }) {
    return groups.map((group) {
      if (group.groupId != groupId) {
        return group;
      }
      final items = [...group.items]..sort((left, right) => left.order.compareTo(right.order));
      final index = items.indexWhere((item) => item.itemId == itemId);
      if (index < 0) {
        return group;
      }
      final target = (index + delta).clamp(0, items.length - 1);
      if (target == index) {
        return group;
      }
      final item = items.removeAt(index);
      items.insert(target, item);
      return group.copyWith(items: normalizeItemOrders(items));
    }).toList(growable: false);
  }

  static List<TenantAdminAccountProfileGalleryGroupDraft> normalizeGroupOrders(
    List<TenantAdminAccountProfileGalleryGroupDraft> groups,
  ) {
    return [
      for (var index = 0; index < groups.length; index++)
        groups[index].copyWith(
          order: index,
          items: normalizeItemOrders(groups[index].items),
        ),
    ];
  }

  static List<TenantAdminAccountProfileGalleryItemDraft> normalizeItemOrders(
    List<TenantAdminAccountProfileGalleryItemDraft> items,
  ) {
    return [
      for (var index = 0; index < items.length; index++)
        items[index].copyWith(order: index),
    ];
  }

  static int totalItemCount(List<TenantAdminAccountProfileGalleryGroupDraft> groups) {
    return groups.fold<int>(
      0,
      (count, group) => count + group.items.length,
    );
  }

  static String _nextGroupId(List<TenantAdminAccountProfileGalleryGroupDraft> groups) {
    final existing = groups.map((group) => group.groupId).toSet();
    var candidate = groups.length + 1;
    while (existing.contains('gallery-group-$candidate')) {
      candidate += 1;
    }
    return 'gallery-group-$candidate';
  }

  static String _nextItemId(List<TenantAdminAccountProfileGalleryGroupDraft> groups) {
    final existing = groups
        .expand((group) => group.items)
        .map((item) => item.itemId)
        .toSet();
    var candidate = existing.length + 1;
    while (existing.contains('gallery-item-$candidate')) {
      candidate += 1;
    }
    return 'gallery-item-$candidate';
  }
}
