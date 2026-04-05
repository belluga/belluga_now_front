import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';

class TenantAdminLegacyEventPartiesSummary {
  TenantAdminLegacyEventPartiesSummary({
    required this.scannedValue,
    required this.invalidValue,
    required this.repairedValue,
    required this.unchangedValue,
    required this.failedValue,
  });

  final TenantAdminCountValue scannedValue;
  final TenantAdminCountValue invalidValue;
  final TenantAdminCountValue repairedValue;
  final TenantAdminCountValue unchangedValue;
  final TenantAdminCountValue failedValue;

  int get scanned => scannedValue.value;
  int get invalid => invalidValue.value;
  int get repaired => repairedValue.value;
  int get unchanged => unchangedValue.value;
  int get failed => failedValue.value;
}
