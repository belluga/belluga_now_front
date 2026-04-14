import 'dart:typed_data';

class TenantAdminPickedBinaryFile {
  const TenantAdminPickedBinaryFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });

  final String name;
  final Uint8List bytes;
  final String? mimeType;
}

Future<TenantAdminPickedBinaryFile?> pickTenantAdminFaviconFile() {
  throw UnsupportedError('Device favicon selection is only available on web.');
}
