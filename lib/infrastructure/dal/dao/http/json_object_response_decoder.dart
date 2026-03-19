import 'dart:convert';

class JsonObjectResponseDecoder {
  const JsonObjectResponseDecoder();

  Map<String, dynamic> decode(
    dynamic raw, {
    required Uri endpoint,
  }) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        throw Exception(
          'Environment response body is empty for $endpoint.',
        );
      }
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      throw Exception(
        'Environment response is not an object for $endpoint.',
      );
    }
    if (raw is List<int>) {
      final decodedRaw = utf8.decode(raw, allowMalformed: true);
      return decode(decodedRaw, endpoint: endpoint);
    }
    throw Exception(
      'Unexpected environment payload type (${raw.runtimeType}) for $endpoint.',
    );
  }
}
