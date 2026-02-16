import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:web/web.dart' as web;

@JS('JSON.stringify')
external JSString stringify(JSAny? value);

@JS('__brandingPayload')
external JSAny? get brandingPayload;

class AppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() {
    // Fast path: if the host page has already resolved branding, read it from the
    // global variable instead of waiting for an event we might miss.
    final preResolved = brandingPayload;
    if (preResolved != null) {
      try {
        final jsonString = stringify(preResolved).toDart;
        final decoded = jsonDecode(jsonString);
        final payload = _extractPayload(decoded);
        if (_isAppDataPayload(payload)) {
          return Future.value(AppDataDTO.fromJson(payload));
        }
      } catch (error) {
        // Ignore invalid/unreadable branding payload.
      }
    }

    final completer = Completer<AppDataDTO>();

    // Safety timeout so the app can fall back instead of hanging if the
    // brandingReady event is never dispatched (e.g., blocked fetch, cache issues).
    Timer? timeoutTimer;
    late final web.EventListener listener;

    void clearAndCompleteError(Object error) {
      timeoutTimer?.cancel();
      web.window.removeEventListener('brandingReady', listener);
      if (!completer.isCompleted) {
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
        final payload = _extractPayload(data);
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

    timeoutTimer = Timer(const Duration(seconds: 6), () {
      clearAndCompleteError(
        TimeoutException('brandingReady event not received'),
      );
    });

    return completer.future;
  }

  Map<String, dynamic> _extractPayload(Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      return const <String, dynamic>{};
    }
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return decoded;
  }

  bool _isAppDataPayload(Map<String, dynamic> payload) {
    return payload['type'] != null &&
        payload['name'] != null &&
        payload['main_domain'] != null &&
        payload['theme_data_settings'] != null;
  }
}
