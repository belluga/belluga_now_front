import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:web/web.dart' as web;

@JS('JSON.stringify')
external JSString stringify(JSAny? value);

class AppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() {
    final completer = Completer<AppDataDTO>();

    final listener = (web.Event event) {
      final customEvent = event as web.CustomEvent;
      final jsDetail = customEvent.detail;

      if (jsDetail != null) {
        final jsonString = stringify(jsDetail).toDart;
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        completer.complete(AppDataDTO.fromJson(data));
      } else {
        completer.completeError(
          Exception('Branding payload missing on brandingReady event'),
        );
      }
    }.toJS;

    web.window.addEventListener(
      'brandingReady',
      listener,
      web.AddEventListenerOptions(once: true),
    );

    return completer.future;
  }
}
