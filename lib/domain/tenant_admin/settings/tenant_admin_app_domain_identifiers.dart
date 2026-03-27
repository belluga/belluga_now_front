import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';

class TenantAdminAppDomainIdentifiers {
  TenantAdminAppDomainIdentifiers({
    required this.androidAppIdentifierValue,
    required this.iosBundleIdValue,
  });

  TenantAdminAppDomainIdentifiers.empty()
      : androidAppIdentifierValue = null,
        iosBundleIdValue = null;

  final TenantAdminAndroidAppIdentifierValue? androidAppIdentifierValue;
  final TenantAdminIosBundleIdentifierValue? iosBundleIdValue;

  String? get androidAppIdentifier =>
      androidAppIdentifierValue?.value;
  String? get iosBundleId =>
      iosBundleIdValue?.value;
}
