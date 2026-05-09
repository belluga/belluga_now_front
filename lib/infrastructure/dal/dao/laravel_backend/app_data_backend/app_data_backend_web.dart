import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/web_bootstrap_handshake.dart';
import 'package:web/web.dart' as web;

@JS('JSON.stringify')
external JSString stringify(JSAny? value);

@JS('__brandingPayload')
external JSAny? get brandingPayload;

@JS('__brandingBootstrapError')
external JSString? get brandingBootstrapError;

class AppDataBackend implements AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() {
    final initialRawPayload = brandingPayload;

    return WebBootstrapHandshake<AppDataDTO>(
      initialValue: _tryDecodeAppData(initialRawPayload),
      initialErrorMessage: _readBootstrapError(),
      hasInitialRawPayload: initialRawPayload != null,
      timeout: const Duration(seconds: 15),
      waitForEventValue: _waitForBrandingReadyPayload,
    ).resolve();
  }

  String? _readBootstrapError() {
    final error = brandingBootstrapError?.toDart.trim();
    if (error == null || error.isEmpty) {
      return null;
    }
    return error;
  }

  Future<AppDataDTO> _waitForBrandingReadyPayload() {
    final completer = Completer<AppDataDTO>();
    late final web.EventListener listener;

    void completeError(Object error) {
      web.window.removeEventListener('brandingReady', listener);
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    listener = (web.Event event) {
      web.window.removeEventListener('brandingReady', listener);
      final customEvent = event as web.CustomEvent;
      final jsDetail = customEvent.detail;
      final resolved = _tryDecodeAppData(jsDetail);

      if (resolved != null) {
        completer.complete(resolved);
        return;
      }

      completeError(
        Exception('Branding payload missing on brandingReady event'),
      );
    }.toJS;

    web.window.addEventListener(
      'brandingReady',
      listener,
      web.AddEventListenerOptions(once: true),
    );

    return completer.future;
  }

  AppDataDTO? _tryDecodeAppData(JSAny? source) {
    if (source == null) {
      return null;
    }

    try {
      final jsonString = stringify(source).toDart;
      final decoded = jsonDecode(jsonString);
      final payload = _extractPayload(decoded);
      if (_isAppDataPayload(payload)) {
        return AppDataDTO.fromJson(payload);
      }
    } catch (error) {
      // Ignore invalid/unreadable branding payload.
    }

    return null;
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
