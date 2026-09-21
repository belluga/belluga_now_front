import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

final class TenantAdminProfileTypeCapabilityEntry {
  const TenantAdminProfileTypeCapabilityEntry({
    required this.keyValue,
    required this.configured,
    this.effective,
  });

  final TenantAdminRequiredTextValue keyValue;
  final TenantAdminProfileTypeCapabilityValue configured;
  final TenantAdminProfileTypeCapabilityValue? effective;

  String get key => keyValue.value;

  TenantAdminProfileTypeCapabilityEntry withConfigured(
    TenantAdminProfileTypeCapabilityValue nextConfigured,
  ) {
    return TenantAdminProfileTypeCapabilityEntry(
      keyValue: keyValue,
      configured: nextConfigured,
      effective: effective,
    );
  }
}
