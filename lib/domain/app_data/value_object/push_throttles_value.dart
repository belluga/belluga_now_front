import 'dart:convert';

import 'package:value_object_pattern/value_object.dart';

class PushThrottlesValue extends ValueObject<Map<String, dynamic>> {
  PushThrottlesValue([Map<String, dynamic>? rawMap])
      : super(defaultValue: const <String, dynamic>{}, isRequired: false) {
    parse(rawMap == null ? null : jsonEncode(rawMap));
  }

  @override
  Map<String, dynamic> doParse(dynamic parseValue) {
    if (parseValue is Map) {
      return Map<String, dynamic>.unmodifiable(
        Map<String, dynamic>.from(parseValue),
      );
    }

    if (parseValue is String) {
      final normalized = parseValue.trim();
      if (normalized.isEmpty) {
        return defaultValue;
      }

      final decoded = jsonDecode(normalized);
      if (decoded is Map) {
        return Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(decoded),
        );
      }
    }

    return defaultValue;
  }

  dynamic operator [](String key) => value[key];
}
