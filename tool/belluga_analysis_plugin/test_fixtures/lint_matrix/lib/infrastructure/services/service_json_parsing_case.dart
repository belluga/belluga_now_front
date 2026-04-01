import 'dart:convert';

class _ServiceDto {
  const _ServiceDto();

  factory _ServiceDto.fromJson(Map<String, dynamic> payload) {
    return const _ServiceDto();
  }
}

class ServiceJsonParsingCase {
  void parse(Map<String, dynamic> payload, String raw) {
    // expect_lint: service_json_parsing_forbidden
    _ServiceDto.fromJson(payload);

    // expect_lint: service_json_parsing_forbidden
    json.decode(raw);
  }
}
