class RawJsonEnvelopeDecoder {
  const RawJsonEnvelopeDecoder();

  Map<String, dynamic> decodeRootMap(
    Object? rawResponse, {
    required String label,
  }) {
    if (rawResponse is Map<String, dynamic>) {
      return rawResponse;
    }
    if (rawResponse is Map) {
      return Map<String, dynamic>.from(rawResponse);
    }
    throw Exception('Unexpected $label response shape.');
  }

  Map<String, dynamic> decodeItemMap(
    Object? rawResponse, {
    required String label,
  }) {
    final root = decodeRootMap(rawResponse, label: label);
    final data = root['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return root;
  }

  List<Map<String, dynamic>> decodeListMap(
    Object? rawResponse, {
    required String label,
    bool allowRawList = false,
  }) {
    Object? listCandidate;
    if (rawResponse is Map || rawResponse is Map<String, dynamic>) {
      final root = decodeRootMap(rawResponse, label: label);
      listCandidate = root['data'];
    } else if (allowRawList) {
      listCandidate = rawResponse;
    } else {
      throw Exception('Unexpected $label list response shape.');
    }

    if (listCandidate is List) {
      return listCandidate
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    }
    throw Exception('Unexpected $label list response shape.');
  }

  Map<String, dynamic> decodeDataMap(
    Object? rawResponse, {
    required String label,
    bool fallbackToRoot = true,
    bool emptyWhenDataIsNotMap = false,
  }) {
    final root = decodeRootMap(rawResponse, label: label);
    final data = root['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (root.containsKey('data') && emptyWhenDataIsNotMap) {
      return const <String, dynamic>{};
    }
    if (fallbackToRoot) {
      return root;
    }
    throw Exception('Unexpected $label response shape.');
  }

  Map<String, dynamic> decodeEnvironmentMap(
    Object? rawResponse, {
    required String label,
  }) {
    final root = decodeRootMap(rawResponse, label: label);
    final data = root['data'];
    if (data == null) {
      return root;
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('Unexpected $label response shape.');
  }
}
