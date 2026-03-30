import 'dart:typed_data';

export 'value_objects/tenant_admin_media_upload_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminMediaUpload {
  TenantAdminMediaUpload({
    required this.bytes,
    required this.fileNameValue,
    required this.mimeTypeValue,
  });

  final Uint8List bytes;
  final TenantAdminRequiredTextValue fileNameValue;
  final TenantAdminOptionalTextValue mimeTypeValue;

  String get fileName => fileNameValue.value;
  String? get mimeType => mimeTypeValue.nullableValue;
}
