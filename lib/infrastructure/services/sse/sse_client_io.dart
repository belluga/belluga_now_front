import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:belluga_now/infrastructure/services/sse/sse_message.dart';

import 'sse_client.dart';

class _IoSseClient implements SseClient {
  @override
  Stream<SseMessage> connect(
    Uri uri, {
    Map<String, String>? headers,
    String? lastEventId,
  }) {
    final controller = StreamController<SseMessage>();
    final client = HttpClient();
    HttpClientRequest? request;
    HttpClientResponse? response;

    var closed = false;

    Future<void> close() async {
      if (closed) {
        return;
      }
      closed = true;
      client.close(force: true);
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller.onCancel = () async {
      await close();
    };

    () async {
      try {
        request = await client.getUrl(uri);
        request!.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
        if (lastEventId != null && lastEventId.isNotEmpty) {
          request!.headers.set('Last-Event-ID', lastEventId);
        }
        headers?.forEach((key, value) {
          request!.headers.set(key, value);
        });
        response = await request!.close();

        String? currentEvent;
        String? currentId;
        final dataLines = <String>[];

        void dispatch() {
          if (dataLines.isEmpty) {
            currentEvent = null;
            currentId = null;
            return;
          }
          final message = SseMessage(
            data: dataLines.join('\n'),
            event: currentEvent,
            id: currentId,
          );
          if (controller.isClosed) {
            dataLines.clear();
            currentEvent = null;
            currentId = null;
            return;
          }
          controller.add(message);
          dataLines.clear();
          currentEvent = null;
          currentId = null;
        }

        await for (final line
            in response!.transform(utf8.decoder).transform(const LineSplitter())) {
          if (line.isEmpty) {
            dispatch();
            continue;
          }
          if (line.startsWith(':')) {
            continue;
          }
          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
            continue;
          }
          if (line.startsWith('id:')) {
            currentId = line.substring(3).trim();
            continue;
          }
          if (line.startsWith('data:')) {
            dataLines.add(line.substring(5).trim());
            continue;
          }
        }

        dispatch();
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
        await close();
      }
    }();

    return controller.stream;
  }
}

SseClient getSseClient() => _IoSseClient();
