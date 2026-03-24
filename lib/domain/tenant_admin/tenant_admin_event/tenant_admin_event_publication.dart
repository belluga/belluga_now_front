part of '../tenant_admin_event.dart';

class TenantAdminEventPublication {
  const TenantAdminEventPublication({
    required this.statusValue,
    TenantAdminOptionalDateTimeValue? publishAtValue,
  }) : publishAtValue =
            publishAtValue ?? const TenantAdminOptionalDateTimeValue(null);

  final TenantAdminRequiredTextValue statusValue;
  final TenantAdminOptionalDateTimeValue publishAtValue;

  String get status => statusValue.value;
  DateTime? get publishAt => publishAtValue.value;
}
