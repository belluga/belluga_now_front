import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

@JS('JSON.stringify')
external JSString stringify(JSAny? value);

class AppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() {
    final completer = Completer<AppDataDTO>();

    // Safety timeout so the app can fall back instead of hanging if the
    // brandingReady event is never dispatched (e.g., blocked fetch, cache issues).
    Timer? timeoutTimer;
    late final web.EventListener listener;

    void clearAndCompleteError(Object error) {
      timeoutTimer?.cancel();
      web.window.removeEventListener('brandingReady', listener);
      if (!completer.isCompleted) {
        debugPrint('[AppDataBackendWeb] Failing to fetch branding: $error');
        completer.completeError(error);
      }
    }

    listener = (web.Event event) {
      final customEvent = event as web.CustomEvent;
      final jsDetail = customEvent.detail;

      timeoutTimer?.cancel();

      if (jsDetail != null) {
        final jsonString = stringify(jsDetail).toDart;
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final payload = (data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : data;
        debugPrint(
          '[AppDataBackendWeb] Received branding payload with keys: ${payload.keys.join(', ')}',
        );
        completer.complete(AppDataDTO.fromJson(payload));
      } else {
        clearAndCompleteError(
          Exception('Branding payload missing on brandingReady event'),
        );
      }
    }.toJS;

    web.window.addEventListener(
      'brandingReady',
      listener,
      web.AddEventListenerOptions(once: true),
    );

    timeoutTimer = Timer(const Duration(seconds: 3), () {
      clearAndCompleteError(
        TimeoutException('brandingReady event not received'),
      );
    });

    return completer.future;
  }
}
