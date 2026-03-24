import 'dart:typed_data';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminMediaUpload {
  TenantAdminMediaUpload({
    required this.bytes,
    required Object fileName,
    Object? mimeType,
  })  : fileNameValue = tenantAdminRequiredText(fileName),
        mimeTypeValue = tenantAdminOptionalText(mimeType);

  final Uint8List bytes;
  final TenantAdminRequiredTextValue fileNameValue;
  final TenantAdminOptionalTextValue mimeTypeValue;

  String get fileName => fileNameValue.value;
  String? get mimeType => mimeTypeValue.nullableValue;
}
