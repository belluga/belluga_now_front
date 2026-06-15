import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_nested_profile_group_operations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TenantAdminNestedProfileGroupOperations.rename', () {
    test('keeps the previous label during transient blank edits', () {
      final groups = [
        _group(id: 'bandas', label: 'Bandas', order: 0),
        _group(id: 'convidados', label: 'Convidados', order: 1),
      ];
      late List<TenantAdminNestedProfileGroup> renamed;

      expect(
        () {
          renamed = TenantAdminNestedProfileGroupOperations.rename(
            groups,
            groupId: 'bandas',
            label: '   ',
          );
        },
        returnsNormally,
      );

      expect(renamed[0].label, 'Bandas');
      expect(renamed[1].label, 'Convidados');
    });

    test('stores trimmed non-empty labels', () {
      final groups = [
        _group(id: 'bandas', label: 'Bandas', order: 0),
      ];

      final renamed = TenantAdminNestedProfileGroupOperations.rename(
        groups,
        groupId: 'bandas',
        label: '  Expositores  ',
      );

      expect(renamed.single.label, 'Expositores');
    });
  });
}

TenantAdminNestedProfileGroup _group({
  required String id,
  required String label,
  required int order,
}) {
  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue(id),
    labelValue: TenantAdminNestedProfileGroupTextValue(label),
    orderValue: TenantAdminNestedProfileGroupOrderValue(order),
  );
}
