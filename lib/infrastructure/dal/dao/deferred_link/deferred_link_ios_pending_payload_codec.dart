import 'dart:convert';

import 'package:belluga_now/infrastructure/services/deferred_link_native_payload.dart';

class DeferredLinkIosPendingPayloadCodec {
  const DeferredLinkIosPendingPayloadCodec();

  DeferredLinkNativePayload? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) {
      return null;
    }

    final payload = DeferredLinkNativePayload(
      resolverPayload: _normalizeText(decoded['resolver_payload']),
      storeChannel: _normalizeText(decoded['store_channel']),
    );
    return payload.hasAnyValue ? payload : null;
  }

  String encode(DeferredLinkNativePayload payload) {
    return jsonEncode(<String, Object?>{
      'resolver_payload': _normalizeText(payload.resolverPayload),
      'store_channel': _normalizeText(payload.storeChannel),
    });
  }

  String? _normalizeText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
