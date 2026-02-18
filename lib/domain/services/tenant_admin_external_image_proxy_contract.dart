import 'dart:typed_data';

abstract class TenantAdminExternalImageProxyContract {
  Future<Uint8List> fetchExternalImageBytes({
    required String imageUrl,
  });
}

