import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';

typedef TenantAdminAppDomainIdentifiersPrimString = String;
typedef TenantAdminAppDomainIdentifiersPrimInt = int;
typedef TenantAdminAppDomainIdentifiersPrimBool = bool;
typedef TenantAdminAppDomainIdentifiersPrimDouble = double;
typedef TenantAdminAppDomainIdentifiersPrimDateTime = DateTime;
typedef TenantAdminAppDomainIdentifiersPrimDynamic = dynamic;

class TenantAdminAppDomainIdentifiers {
  TenantAdminAppDomainIdentifiers({
    required TenantAdminAppDomainIdentifiersPrimString? androidAppIdentifier,
    required TenantAdminAppDomainIdentifiersPrimString? iosBundleId,
  })  : androidAppIdentifierValue =
            _buildAndroidAppIdentifierValue(androidAppIdentifier),
        iosBundleIdValue = _buildIosBundleIdValue(iosBundleId);

  TenantAdminAppDomainIdentifiers.empty()
      : androidAppIdentifierValue = null,
        iosBundleIdValue = null;

  final TenantAdminAndroidAppIdentifierValue? androidAppIdentifierValue;
  final TenantAdminIosBundleIdentifierValue? iosBundleIdValue;

  TenantAdminAppDomainIdentifiersPrimString? get androidAppIdentifier =>
      androidAppIdentifierValue?.value;
  TenantAdminAppDomainIdentifiersPrimString? get iosBundleId =>
      iosBundleIdValue?.value;

  static TenantAdminAndroidAppIdentifierValue? _buildAndroidAppIdentifierValue(
    TenantAdminAppDomainIdentifiersPrimString? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final value = TenantAdminAndroidAppIdentifierValue()..parse(normalized);
    return value;
  }

  static TenantAdminIosBundleIdentifierValue? _buildIosBundleIdValue(
    TenantAdminAppDomainIdentifiersPrimString? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final value = TenantAdminIosBundleIdentifierValue()..parse(normalized);
    return value;
  }
}
