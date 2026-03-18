import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';

class TenantAdminAppDomainIdentifiers {
  TenantAdminAppDomainIdentifiers({
    required String? androidAppIdentifier,
    required String? iosBundleId,
  })  : androidAppIdentifierValue =
            _buildAndroidAppIdentifierValue(androidAppIdentifier),
        iosBundleIdValue = _buildIosBundleIdValue(iosBundleId);

  TenantAdminAppDomainIdentifiers.empty()
      : androidAppIdentifierValue = null,
        iosBundleIdValue = null;

  final TenantAdminAndroidAppIdentifierValue? androidAppIdentifierValue;
  final TenantAdminIosBundleIdentifierValue? iosBundleIdValue;

  String? get androidAppIdentifier => androidAppIdentifierValue?.value;
  String? get iosBundleId => iosBundleIdValue?.value;

  static TenantAdminAndroidAppIdentifierValue? _buildAndroidAppIdentifierValue(
    String? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final value = TenantAdminAndroidAppIdentifierValue()..parse(normalized);
    return value;
  }

  static TenantAdminIosBundleIdentifierValue? _buildIosBundleIdValue(
    String? raw,
  ) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    final value = TenantAdminIosBundleIdentifierValue()..parse(normalized);
    return value;
  }
}
