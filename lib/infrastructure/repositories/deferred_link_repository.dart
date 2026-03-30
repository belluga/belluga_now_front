import 'dart:convert';
import 'dart:io';

import 'package:belluga_now/domain/repositories/deferred_link_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/deferred_links_backend/laravel_deferred_link_backend.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_backend_contract.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeferredLinkRepository implements DeferredLinkRepositoryContract {
  DeferredLinkRepository({
    MethodChannel? channel,
    FlutterSecureStorage? storage,
    bool Function()? isAndroid,
    DeferredLinkBackendContract? backend,
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _storage = storage ?? const FlutterSecureStorage(),
        _isAndroid = isAndroid ??
            (() {
              if (kIsWeb) {
                return false;
              }
              return Platform.isAndroid;
            }),
        _backend = backend ?? LaravelDeferredLinkBackend();

  static const String _channelName = 'com.belluga_now/deferred_link';
  static const String _captureAttemptedKey = 'deferred_link_capture_attempted';
  static const String _consumedReferrerHashKey =
      'deferred_link_consumed_referrer_hash';

  final MethodChannel _channel;
  final FlutterSecureStorage _storage;
  final bool Function() _isAndroid;
  final DeferredLinkBackendContract _backend;

  @override
  Future<DeferredLinkCaptureResult> captureFirstOpenInviteCode() async {
    if (!_isAndroid()) {
      return const DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.skipped,
        failureReason: 'unsupported_platform',
      );
    }

    final attempted = await _storage.read(key: _captureAttemptedKey);
    if (attempted == '1') {
      return const DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.skipped,
        failureReason: 'already_attempted',
      );
    }

    await _storage.write(key: _captureAttemptedKey, value: '1');

    final payload = await _fetchInstallReferrerPayload();
    final installReferrer = _normalizeText(
      payload?['install_referrer'] ?? payload?['referrer'],
    );
    final fallbackStoreChannel =
        payload == null ? null : _extractStoreChannel(payload);

    final resolverData = await _resolveWithBackend(
      installReferrer: installReferrer,
      fallbackStoreChannel: fallbackStoreChannel,
    );

    final status = _normalizeText(resolverData['status']);
    final code = _normalizeText(resolverData['code']);
    final storeChannel =
        _normalizeText(resolverData['store_channel']) ?? fallbackStoreChannel;
    final failureReason = _normalizeText(resolverData['failure_reason']);

    if (status == 'captured' && code != null) {
      if (installReferrer != null) {
        final hash = sha256.convert(utf8.encode(installReferrer)).toString();
        final consumedHash = await _storage.read(key: _consumedReferrerHashKey);
        if (consumedHash == hash) {
          return DeferredLinkCaptureResult(
            status: DeferredLinkCaptureStatus.notCaptured,
            storeChannel: storeChannel,
            failureReason: 'referrer_already_consumed',
          );
        }

        await _storage.write(key: _consumedReferrerHashKey, value: hash);
      }

      return DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.captured,
        code: code,
        storeChannel: storeChannel,
      );
    }

    return DeferredLinkCaptureResult(
      status: DeferredLinkCaptureStatus.notCaptured,
      storeChannel: storeChannel,
      failureReason: failureReason ?? 'resolver_not_captured',
    );
  }

  Future<Map<String, dynamic>?> _fetchInstallReferrerPayload() async {
    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        'getInstallReferrer',
      );
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<Map<String, dynamic>> _resolveWithBackend({
    String? installReferrer,
    String? fallbackStoreChannel,
  }) async {
    try {
      return await _backend.resolveDeferredLink(
        platform: 'android',
        installReferrer: installReferrer,
        storeChannel: fallbackStoreChannel,
      );
    } catch (_) {
      return <String, dynamic>{
        'status': 'not_captured',
        'code': null,
        'store_channel': fallbackStoreChannel,
        'failure_reason': 'resolver_unavailable',
      };
    }
  }

  Map<String, String> _parseQueryParameters(String raw) {
    final normalized = raw.startsWith('?') ? raw.substring(1) : raw;
    try {
      return Uri.splitQueryString(normalized);
    } catch (_) {
      return const <String, String>{};
    }
  }

  String? _extractStoreChannel(Map<String, dynamic> payload) {
    final fromStore = _normalizeText(payload['store_channel']);
    if (fromStore != null) {
      return fromStore;
    }

    final referrer = _normalizeText(
      payload['install_referrer'] ?? payload['referrer'],
    );
    if (referrer == null) {
      return null;
    }
    final params = _parseQueryParameters(referrer);
    return _normalizeText(
      params['store_channel'] ?? params['utm_source'] ?? params['channel'],
    );
  }

  String? _normalizeText(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }
}
