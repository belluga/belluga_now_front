import 'dart:convert';
import 'dart:io';

import 'package:belluga_now/domain/repositories/deferred_link_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/deferred_link/deferred_link_ios_pending_payload_codec.dart';
import 'package:belluga_now/infrastructure/dal/dao/deferred_link/deferred_link_local_state.dart';
import 'package:belluga_now/infrastructure/dal/dao/deferred_link/deferred_link_local_state_storage_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/deferred_links_backend/laravel_deferred_link_backend.dart';
import 'package:belluga_now/infrastructure/dal/dto/deferred_link/deferred_link_resolution_dto.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_native_payload.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_native_source_contract.dart';
import 'package:belluga_now/infrastructure/services/method_channel_deferred_link_native_source.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeferredLinkRepository implements DeferredLinkRepositoryContract {
  DeferredLinkRepository({
    MethodChannel? channel,
    FlutterSecureStorage? storage,
    DeferredLinkLocalStateStorageContract? localStateStorage,
    List<Duration>? iosRetryDelays,
    String Function()? platformResolver,
    DeferredLinkBackendContract? backend,
    DeferredLinkNativeSourceContract? nativeSource,
  }) : _localStateStorage =
           localStateStorage ??
           DeferredLinkLocalStateStorage(legacyStorage: storage),
       _iosRetryDelays = List<Duration>.unmodifiable(
         iosRetryDelays ?? _defaultIosRetryDelays,
       ),
       _platformResolver =
           platformResolver ??
           (() {
             if (kIsWeb) {
               return 'web';
             }
             if (Platform.isAndroid) {
               return 'android';
             }
             if (Platform.isIOS) {
               return 'ios';
             }
             return 'unsupported';
           }),
       _backend = backend ?? LaravelDeferredLinkBackend(),
       _nativeSource =
           nativeSource ??
           MethodChannelDeferredLinkNativeSource(
             channel: channel ?? const MethodChannel(_channelName),
           );

  static const String _channelName = 'com.belluga_now/deferred_link';
  static const String _captureAttemptedKey = 'deferred_link_capture_attempted';
  static const String _consumedReferrerHashKey =
      'deferred_link_consumed_referrer_hash';
  static const String _iosCaptureFinalizedKey =
      'deferred_link_ios_capture_finalized';
  static const String _iosPendingPayloadKey =
      'deferred_link_ios_pending_payload';
  static const List<Duration> _defaultIosRetryDelays = <Duration>[
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
  ];
  static const DeferredLinkIosPendingPayloadCodec _iosPendingPayloadCodec =
      DeferredLinkIosPendingPayloadCodec();

  final DeferredLinkLocalStateStorageContract _localStateStorage;
  final List<Duration> _iosRetryDelays;
  final String Function() _platformResolver;
  final DeferredLinkBackendContract _backend;
  final DeferredLinkNativeSourceContract _nativeSource;

  @override
  Future<DeferredLinkCaptureResult> captureFirstOpenInviteCode() async {
    final resolvedPlatform = _normalizeText(_platformResolver()) ?? 'unknown';
    final supportedPlatform = _normalizeSupportedPlatform(resolvedPlatform);
    if (supportedPlatform == null) {
      return DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.skipped,
        platformValue: deferredLinkPlatform(resolvedPlatform),
        failureReasonValue: deferredLinkFailureReason('unsupported_platform'),
      );
    }

    final isIosPlatform = supportedPlatform == 'ios';
    if (isIosPlatform) {
      final finalized = await _readLocalStateBestEffort(
        _iosCaptureFinalizedKey,
      );
      if (finalized == '1') {
        return DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.skipped,
          platformValue: deferredLinkPlatform(supportedPlatform),
          failureReasonValue: deferredLinkFailureReason('already_attempted'),
        );
      }
    }

    if (!isIosPlatform) {
      final attempted = await _readLocalStateBestEffort(_captureAttemptedKey);
      if (attempted == '1') {
        return DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.skipped,
          platformValue: deferredLinkPlatform(supportedPlatform),
          failureReasonValue: deferredLinkFailureReason('already_attempted'),
        );
      }

      // Android install referrer is intentionally one-shot per install. We mark
      // the attempt before the native read so relaunches cannot keep replaying
      // a mutable referrer surface after the first bootstrap pass begins.
      await _writeLocalStateBestEffort(_captureAttemptedKey, '1');
    }

    if (isIosPlatform) {
      final attempt = await _captureIosWithinCall(platform: supportedPlatform);
      if (!attempt.shouldRetry) {
        final finalized = await _markIosCaptureFinalized();
        if (finalized) {
          await _deleteLocalStateBestEffort(_iosPendingPayloadKey);
        }
      }
      return attempt.result;
    }

    final attempt = await _captureOnce(
      platform: supportedPlatform,
      allowIosRetry: false,
    );
    return attempt.result;
  }

  Future<String?> _readLocalStateBestEffort(String key) async {
    String? value;
    try {
      value = await _localStateStorage.read(key);
    } catch (error, stackTrace) {
      debugPrint(
        'DeferredLinkRepository local-state read failed for $key: '
        '$error\n$stackTrace',
      );
    }
    return value;
  }

  Future<bool> _writeLocalStateBestEffort(String key, String value) async {
    var success = false;
    try {
      await _localStateStorage.write(key, value);
      success = true;
    } catch (error, stackTrace) {
      debugPrint(
        'DeferredLinkRepository local-state write failed for $key: '
        '$error\n$stackTrace',
      );
    }
    return success;
  }

  Future<bool> _deleteLocalStateBestEffort(String key) async {
    var success = false;
    try {
      await _localStateStorage.delete(key);
      success = true;
    } catch (error, stackTrace) {
      debugPrint(
        'DeferredLinkRepository local-state delete failed for $key: '
        '$error\n$stackTrace',
      );
    }
    return success;
  }

  Future<_DeferredLinkCaptureAttempt> _captureFromPayload({
    required String platform,
    required DeferredLinkNativePayload? payload,
    required bool allowIosRetry,
  }) async {
    final resolverPayload = _normalizeText(payload?.resolverPayload);
    final fallbackStoreChannel = _normalizeText(payload?.storeChannel);

    if (resolverPayload == null && fallbackStoreChannel == null) {
      return _DeferredLinkCaptureAttempt(
        result: DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.notCaptured,
          platformValue: deferredLinkPlatform(platform),
          failureReasonValue: deferredLinkFailureReason('referrer_unavailable'),
        ),
        shouldRetry:
            allowIosRetry &&
            _isIosRetryableFailure(
              failureReason: 'referrer_unavailable',
              hasResolverPayload: false,
            ),
      );
    }

    final resolverData = await _resolveWithBackend(
      platform: platform,
      resolverPayload: resolverPayload,
      fallbackStoreChannel: fallbackStoreChannel,
    );

    final status = _normalizeText(resolverData.status);
    final code = _normalizeText(resolverData.code);
    final targetPath =
        _normalizeTargetPath(resolverData.targetPath) ??
        (code == null
            ? null
            : Uri(
                path: '/invite',
                queryParameters: <String, String>{'code': code},
              ).toString());
    final storeChannel =
        _normalizeText(resolverData.storeChannel) ?? fallbackStoreChannel;
    final failureReason = _normalizeText(resolverData.failureReason);

    if (status == 'captured' && targetPath != null) {
      if (resolverPayload != null) {
        final hash = sha256.convert(utf8.encode(resolverPayload)).toString();
        final consumedHash = await _readLocalStateBestEffort(
          _consumedReferrerHashKey,
        );
        if (consumedHash == hash) {
          return _DeferredLinkCaptureAttempt(
            result: DeferredLinkCaptureResult(
              status: DeferredLinkCaptureStatus.notCaptured,
              platformValue: deferredLinkPlatform(platform),
              storeChannelValue: storeChannel == null
                  ? null
                  : deferredLinkStoreChannel(storeChannel),
              failureReasonValue: deferredLinkFailureReason(
                'referrer_already_consumed',
              ),
            ),
          );
        }

        await _writeLocalStateBestEffort(_consumedReferrerHashKey, hash);
      }

      return _DeferredLinkCaptureAttempt(
        result: DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.captured,
          platformValue: deferredLinkPlatform(platform),
          codeValue: code == null ? null : deferredLinkCode(code),
          targetPathValue: deferredLinkTargetPath(targetPath),
          storeChannelValue: storeChannel == null
              ? null
              : deferredLinkStoreChannel(storeChannel),
        ),
      );
    }

    final resolvedFailureReason = failureReason ?? 'resolver_not_captured';
    return _DeferredLinkCaptureAttempt(
      result: DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.notCaptured,
        platformValue: deferredLinkPlatform(platform),
        storeChannelValue: storeChannel == null
            ? null
            : deferredLinkStoreChannel(storeChannel),
        failureReasonValue: deferredLinkFailureReason(resolvedFailureReason),
      ),
      shouldRetry:
          allowIosRetry &&
          _isIosRetryableFailure(
            failureReason: resolvedFailureReason,
            hasResolverPayload: resolverPayload != null,
          ),
    );
  }

  Future<_DeferredLinkCaptureAttempt> _captureOnce({
    required String platform,
    required bool allowIosRetry,
  }) async {
    final payload = await _nativeSource.readDeferredPayload(platform: platform);
    return _captureFromPayload(
      platform: platform,
      payload: payload,
      allowIosRetry: allowIosRetry,
    );
  }

  Future<_DeferredLinkCaptureAttempt> _captureIosWithinCall({
    required String platform,
  }) async {
    _DeferredLinkCaptureAttempt? lastAttempt;
    var pendingPayload = await _readPendingIosPayload();
    final attempts = 1 + _iosRetryDelays.length;
    for (var attemptIndex = 0; attemptIndex < attempts; attemptIndex += 1) {
      pendingPayload ??= await _nativeSource.readDeferredPayload(
        platform: platform,
      );
      if (pendingPayload != null) {
        await _persistPendingIosPayload(pendingPayload);
      }

      lastAttempt = await _captureFromPayload(
        platform: platform,
        payload: pendingPayload,
        allowIosRetry: true,
      );
      if (!lastAttempt.shouldRetry) {
        return lastAttempt;
      }
      if (attemptIndex >= _iosRetryDelays.length) {
        break;
      }
      final delay = _iosRetryDelays[attemptIndex];
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
    }

    return lastAttempt!;
  }

  Future<DeferredLinkNativePayload?> _readPendingIosPayload() async {
    final raw = await _readLocalStateBestEffort(_iosPendingPayloadKey);
    return _iosPendingPayloadCodec.decode(raw);
  }

  Future<void> _persistPendingIosPayload(
    DeferredLinkNativePayload payload,
  ) async {
    if (!payload.hasAnyValue) {
      return;
    }
    await _writeLocalStateBestEffort(
      _iosPendingPayloadKey,
      _iosPendingPayloadCodec.encode(payload),
    );
  }

  Future<bool> _markIosCaptureFinalized() async {
    return _writeLocalStateBestEffort(_iosCaptureFinalizedKey, '1');
  }

  bool _isIosRetryableFailure({
    required String failureReason,
    required bool hasResolverPayload,
  }) {
    if (failureReason == 'referrer_unavailable') {
      return true;
    }
    if (failureReason == 'resolver_unavailable' && hasResolverPayload) {
      return true;
    }
    return false;
  }

  Future<DeferredLinkResolutionDto> _resolveWithBackend({
    required String platform,
    String? resolverPayload,
    String? fallbackStoreChannel,
  }) async {
    DeferredLinkResolutionDto resolution;
    try {
      resolution = await _backend.resolveDeferredLink(
        platform: platform,
        resolverPayload: resolverPayload,
        storeChannel: fallbackStoreChannel,
      );
    } catch (_) {
      resolution = DeferredLinkResolutionDto(
        status: 'not_captured',
        storeChannel: fallbackStoreChannel,
        failureReason: 'resolver_unavailable',
      );
    }
    return resolution;
  }

  String? _normalizeSupportedPlatform(String? value) {
    final normalized = _normalizeText(value)?.toLowerCase();
    if (normalized == 'android' || normalized == 'ios') {
      return normalized;
    }
    return null;
  }

  String? _normalizeText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  String? _normalizeTargetPath(Object? value) {
    final text = _normalizeText(value);
    if (text == null || text.startsWith('//') || !text.startsWith('/')) {
      return null;
    }
    final uri = Uri.tryParse(text);
    if (uri == null || uri.hasScheme || uri.hasAuthority) {
      return null;
    }
    return uri.toString();
  }
}

class _DeferredLinkCaptureAttempt {
  const _DeferredLinkCaptureAttempt({
    required this.result,
    this.shouldRetry = false,
  });

  final DeferredLinkCaptureResult result;
  final bool shouldRetry;
}
