import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminHomeFavoritesPinnedProfileSettings {
  const TenantAdminHomeFavoritesPinnedProfileSettings({
    required this.accountProfileIdValue,
    required this.availabilityValue,
    required this.selectedProfileDisplayNameValue,
  });

  final TenantAdminAccountProfileIdValue? accountProfileIdValue;
  final TenantAdminLowercaseTokenValue availabilityValue;
  final TenantAdminOptionalTextValue selectedProfileDisplayNameValue;

  String? get accountProfileId => accountProfileIdValue?.value;
  String get availability => availabilityValue.value;
  String? get selectedProfileDisplayName =>
      selectedProfileDisplayNameValue.nullableValue;

  bool get isAvailable => availability == 'available';
  bool get isUnavailable => availability == 'unavailable';
}
