import 'package:belluga_now/infrastructure/services/sse/sse_message.dart';

import 'sse_client.dart';

class _UnsupportedSseClient implements SseClient {
  @override
  Stream<SseMessage> connect(
    Uri uri, {
    Map<String, String>? headers,
    String? lastEventId,
  }) {
    throw UnsupportedError('SSE is not supported on this platform.');
  }
}

SseClient getSseClient() => _UnsupportedSseClient();
