import 'dart:convert';

import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class ContactAvatarBytesValue extends ValueObject<String> {
  ContactAvatarBytesValue([List<int>? raw])
      : super(defaultValue: '', isRequired: false) {
    if (raw != null && raw.isNotEmpty) {
      parse(base64Encode(raw));
    }
  }

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();

  @override
  void validate(String? newValue) {
    final normalized = (newValue ?? '').trim();
    if (normalized.isEmpty) {
      if (isRequired) {
        throw RequiredValueException();
      }
      return;
    }

    try {
      base64Decode(normalized);
    } catch (_) {
      throw InvalidValueException();
    }
  }

  String? get nullableValue {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  List<int>? get bytes {
    final normalized = nullableValue;
    if (normalized == null) {
      return null;
    }
    return List<int>.unmodifiable(base64Decode(normalized));
  }
}
