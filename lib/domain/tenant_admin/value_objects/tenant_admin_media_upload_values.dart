import 'dart:typed_data';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

TenantAdminMediaUpload tenantAdminMediaUploadFromRaw({
  required Uint8List bytes,
  required Object? fileName,
  Object? mimeType,
}) {
  return TenantAdminMediaUpload(
    bytes: bytes,
    fileNameValue: tenantAdminRequiredText(fileName),
    mimeTypeValue: tenantAdminOptionalText(mimeType),
  );
}
