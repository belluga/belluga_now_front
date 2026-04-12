import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_domain_status_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_date_time_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminDomainEntry {
  TenantAdminDomainEntry({
    required this.idValue,
    required this.pathValue,
    required this.typeValue,
    required this.statusValue,
    TenantAdminOptionalDateTimeValue? createdAtValue,
    TenantAdminOptionalDateTimeValue? updatedAtValue,
    TenantAdminOptionalDateTimeValue? deletedAtValue,
  })  : createdAtValue = createdAtValue ?? TenantAdminOptionalDateTimeValue(),
        updatedAtValue = updatedAtValue ?? TenantAdminOptionalDateTimeValue(),
        deletedAtValue = deletedAtValue ?? TenantAdminOptionalDateTimeValue();

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue pathValue;
  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminDomainStatusValue statusValue;
  final TenantAdminOptionalDateTimeValue createdAtValue;
  final TenantAdminOptionalDateTimeValue updatedAtValue;
  final TenantAdminOptionalDateTimeValue deletedAtValue;

  String get id => idValue.value;
  String get path => pathValue.value;
  String get type => typeValue.value;
  String get status => statusValue.value;
  DateTime? get createdAt => createdAtValue.value;
  DateTime? get updatedAt => updatedAtValue.value;
  DateTime? get deletedAt => deletedAtValue.value;
  bool get isActive => status == TenantAdminDomainStatusValue.active;
  bool get isDeleted => status == TenantAdminDomainStatusValue.deleted;
}
