import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:flutter/foundation.dart';

class TenantAdminNestedProfileGroupOperations {
  const TenantAdminNestedProfileGroupOperations._();

  static List<TenantAdminNestedProfileGroup> append(
    List<TenantAdminNestedProfileGroup> groups, {
    String label = 'Novo grupo',
  }) {
    final nextOrder = groups.length;
    return normalizeOrders([
      ...groups,
      TenantAdminNestedProfileGroup(
        idValue: TenantAdminNestedProfileGroupTextValue(
          'grupo-${DateTime.now().microsecondsSinceEpoch}',
        ),
        labelValue: TenantAdminNestedProfileGroupTextValue(label),
        orderValue: TenantAdminNestedProfileGroupOrderValue(nextOrder),
      ),
    ]);
  }

  static List<TenantAdminNestedProfileGroup> rename(
    List<TenantAdminNestedProfileGroup> groups, {
    required String groupId,
    required String label,
  }) {
    return groups
        .map(
          (group) => group.id == groupId
              ? group.copyWith(
                  labelValue: TenantAdminNestedProfileGroupTextValue(label),
                )
              : group,
        )
        .toList(growable: false);
  }

  static List<TenantAdminNestedProfileGroup> remove(
    List<TenantAdminNestedProfileGroup> groups, {
    required String groupId,
  }) {
    return normalizeOrders(
      groups.where((group) => group.id != groupId).toList(growable: false),
    );
  }

  static List<TenantAdminNestedProfileGroup> move(
    List<TenantAdminNestedProfileGroup> groups, {
    required String groupId,
    required int delta,
  }) {
    final next = [...groups]
      ..sort((left, right) => left.order.compareTo(right.order));
    final index = next.indexWhere((group) => group.id == groupId);
    if (index < 0) {
      return groups;
    }
    final target = (index + delta).clamp(0, next.length - 1);
    if (target == index) {
      return groups;
    }
    final group = next.removeAt(index);
    next.insert(target, group);
    return normalizeOrders(next);
  }

  static List<TenantAdminNestedProfileGroup> toggleMember(
    List<TenantAdminNestedProfileGroup> groups, {
    required String groupId,
    required String profileId,
    required bool selected,
    required VoidCallback onLimit,
  }) {
    return groups.map((group) {
      if (group.id != groupId) {
        return group;
      }
      final current = group.accountProfileIdValues
          .map((entry) => entry.value)
          .toList(growable: true);
      if (selected) {
        if (current.contains(profileId)) {
          return group;
        }
        if (current.length >= 50) {
          onLimit();
          return group;
        }
        current.add(profileId);
      } else {
        current.removeWhere((entry) => entry == profileId);
      }
      return group.copyWith(
        accountProfileIdValues:
            current.map(TenantAdminNestedProfileGroupTextValue.new).toList(),
      );
    }).toList(growable: false);
  }

  static List<TenantAdminNestedProfileGroup> normalizeOrders(
    List<TenantAdminNestedProfileGroup> groups,
  ) {
    return [
      for (var index = 0; index < groups.length; index++)
        groups[index].copyWith(
          orderValue: TenantAdminNestedProfileGroupOrderValue(index),
        ),
    ];
  }

  static List<String> memberIds(List<TenantAdminNestedProfileGroup> groups) {
    final ids = <String>[];
    for (final group in groups) {
      for (final entry in group.accountProfileIdValues) {
        if (!ids.contains(entry.value)) {
          ids.add(entry.value);
        }
      }
    }
    return List<String>.unmodifiable(ids);
  }
}
