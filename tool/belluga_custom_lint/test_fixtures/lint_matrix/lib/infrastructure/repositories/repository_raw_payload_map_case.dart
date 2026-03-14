class RepositoryRawPayloadMapCase {
  // expect_lint: repository_raw_payload_map_forbidden
  Map<String, Object?> extractItem(Object? raw) {
    if (
        // expect_lint: repository_raw_payload_map_forbidden
        raw is Map<String, Object?>) {
      return raw;
    }

    // expect_lint: repository_raw_payload_map_forbidden
    return <String, Object?>{};
  }

  void submit(
    // expect_lint: repository_raw_payload_map_forbidden
    Map<String, Object?> payload,
  ) {
    // expect_lint: repository_raw_payload_map_forbidden
    final requestBody = <String, Object?>{
      'payload': payload,
    };

    final headers = <String, String>{
      'Authorization': 'Bearer token',
    };

    requestBody.length;
    headers.length;
  }

  void castPayload(Object raw) {
    // expect_lint: repository_raw_payload_map_forbidden
    final payload = raw as Map<String, Object?>;
    payload.length;
  }

  void clonePayload(Object raw) {
    // expect_lint: repository_raw_payload_map_forbidden
    final payload = Map<String, Object?>.from(raw as Map);
    payload.length;
  }

  void workaroundWithBareMap(Object? raw) {
    if (
        // expect_lint: repository_raw_payload_map_forbidden
        raw is Map) {
      // expect_lint: repository_raw_payload_map_forbidden
      final payload = raw.cast<String, Object?>();
      payload.length;
    }
  }

  void workaroundWithWhereType(List<Object?> rows) {
    final payload = rows
        // expect_lint: repository_raw_payload_map_forbidden
        .whereType<Map>()
        .map((row) =>
            // expect_lint: repository_raw_payload_map_forbidden
            row.cast<String, Object?>())
        .toList(growable: false);
    payload.length;
  }
}
