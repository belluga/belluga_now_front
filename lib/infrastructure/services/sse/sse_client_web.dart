// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:belluga_now/infrastructure/services/sse/sse_message.dart';

import 'sse_client.dart';

class _WebSseClient implements SseClient {
  @override
  Stream<SseMessage> connect(
    Uri uri, {
    Map<String, String>? headers,
    String? lastEventId,
  }) {
    final controller = StreamController<SseMessage>();
    final eventSource = html.EventSource(uri.toString());

    void handleMessage(
      html.MessageEvent event, {
      String? eventType,
    }) {
      controller.add(
        SseMessage(
          data: event.data?.toString() ?? '',
          event: eventType ?? event.type,
          id: event.lastEventId,
        ),
      );
    }

    eventSource.onMessage.listen((event) {
      handleMessage(event, eventType: event.type);
    });

    for (final eventType in const ['event.created', 'event.updated', 'event.deleted']) {
      eventSource.addEventListener(
        eventType,
        (event) => handleMessage(event as html.MessageEvent, eventType: eventType),
      );
    }

    eventSource.onError.listen((event) {
      if (!controller.isClosed) {
        controller.addError(StateError('SSE connection error'));
      }
    });

    controller.onCancel = () {
      eventSource.close();
    };

    return controller.stream;
  }
}

SseClient getSseClient() => _WebSseClient();
