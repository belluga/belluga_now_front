import 'dart:typed_data';

import 'package:belluga_now/domain/user/value_objects/user_profile_media_bytes_value.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class UserProfileMediaUpload {
  UserProfileMediaUpload({
    required this.bytesValue,
    required this.fileNameValue,
    GenericStringValue? mimeTypeValue,
  }) : mimeTypeValue =
            mimeTypeValue ?? GenericStringValue(isRequired: false, minLenght: null);

  final UserProfileMediaBytesValue bytesValue;
  final GenericStringValue fileNameValue;
  final GenericStringValue mimeTypeValue;

  Uint8List get bytes => bytesValue.value;
  String get fileName => fileNameValue.value;
  String? get mimeType => mimeTypeValue.value.trim().isEmpty ? null : mimeTypeValue.value;
}
