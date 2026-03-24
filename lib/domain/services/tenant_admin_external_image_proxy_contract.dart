import 'dart:typed_data';

typedef TenantAdminExternalImageProxyContractPrimString = String;
typedef TenantAdminExternalImageProxyContractPrimInt = int;
typedef TenantAdminExternalImageProxyContractPrimBool = bool;
typedef TenantAdminExternalImageProxyContractPrimDouble = double;
typedef TenantAdminExternalImageProxyContractPrimDateTime = DateTime;
typedef TenantAdminExternalImageProxyContractPrimDynamic = dynamic;

abstract class TenantAdminExternalImageProxyContract {
  Future<Uint8List> fetchExternalImageBytes({
    required TenantAdminExternalImageProxyContractPrimString imageUrl,
  });
}
