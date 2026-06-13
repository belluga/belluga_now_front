import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';

export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';

class TenantAdminNestedProfileGroup {
  TenantAdminNestedProfileGroup({
    required this.idValue,
    required this.labelValue,
    required this.orderValue,
    List<TenantAdminNestedProfileGroupTextValue>? accountProfileIdValues,
  }) : accountProfileIdValues =
            List<TenantAdminNestedProfileGroupTextValue>.unmodifiable(
          accountProfileIdValues ??
              const <TenantAdminNestedProfileGroupTextValue>[],
        );

  final TenantAdminNestedProfileGroupTextValue idValue;
  final TenantAdminNestedProfileGroupTextValue labelValue;
  final TenantAdminNestedProfileGroupOrderValue orderValue;
  final List<TenantAdminNestedProfileGroupTextValue> accountProfileIdValues;

  String get id => idValue.value;
  String get label => labelValue.value;
  int get order => orderValue.value;

  TenantAdminNestedProfileGroup copyWith({
    TenantAdminNestedProfileGroupTextValue? idValue,
    TenantAdminNestedProfileGroupTextValue? labelValue,
    TenantAdminNestedProfileGroupOrderValue? orderValue,
    List<TenantAdminNestedProfileGroupTextValue>? accountProfileIdValues,
  }) {
    return TenantAdminNestedProfileGroup(
      idValue: idValue ?? this.idValue,
      labelValue: labelValue ?? this.labelValue,
      orderValue: orderValue ?? this.orderValue,
      accountProfileIdValues:
          accountProfileIdValues ?? this.accountProfileIdValues,
    );
  }
}
