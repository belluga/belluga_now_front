// ignore_for_file: unused_element

import 'dart:convert';

class _RepositoryDto {
  const _RepositoryDto();

  factory _RepositoryDto.fromJson(Map<String, dynamic> json) {
    return const _RepositoryDto();
  }

  factory _RepositoryDto.fromMap(Map<String, dynamic> json) {
    return const _RepositoryDto();
  }
}

class FormData {
  FormData.fromMap(Map<String, dynamic> payload);
}

class _RepositoryJsonParsingCase {
  void parse(Map<String, dynamic> payload, String raw) {
    // expect_lint: repository_json_parsing_forbidden
    _RepositoryDto.fromJson(payload);

    // expect_lint: repository_json_parsing_forbidden
    _RepositoryDto.fromMap(payload);

    FormData.fromMap(payload);

    // expect_lint: repository_json_parsing_forbidden
    jsonDecode(raw);
  }
}
