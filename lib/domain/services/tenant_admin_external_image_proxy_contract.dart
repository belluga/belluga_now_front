import 'dart:typed_data';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';

typedef TenantAdminExternalImageProxyContractPrimString = String;
typedef TenantAdminExternalImageProxyContractPrimInt = int;
typedef TenantAdminExternalImageProxyContractPrimBool = bool;
typedef TenantAdminExternalImageProxyContractPrimDouble = double;
typedef TenantAdminExternalImageProxyContractPrimDateTime = DateTime;
typedef TenantAdminExternalImageProxyContractPrimDynamic = dynamic;

abstract class TenantAdminExternalImageProxyContract {
  Future<Uint8List> fetchExternalImageBytes({
    required TenantAdminOptionalUrlValue imageUrl,
  });
}
