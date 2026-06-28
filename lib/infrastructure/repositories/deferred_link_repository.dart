import 'dart:convert';
import 'dart:io';

import 'package:belluga_now/domain/repositories/deferred_link_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/deferred_links_backend/laravel_deferred_link_backend.dart';
import 'package:belluga_now/infrastructure/dal/dto/deferred_link/deferred_link_resolution_dto.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_backend_contract.dart';
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
    String Function()? platformResolver,
    DeferredLinkBackendContract? backend,
    DeferredLinkNativeSourceContract? nativeSource,
  }) : _storage = storage ?? const FlutterSecureStorage(),
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
  static const String _iosTransientAttemptCountKey =
      'deferred_link_ios_transient_attempt_count';
  static const int _iosMaxTransientAttempts = 3;

  final FlutterSecureStorage _storage;
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
      final finalized = await _readStorageBestEffort(_iosCaptureFinalizedKey);
      if (finalized == '1') {
        return DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.skipped,
          platformValue: deferredLinkPlatform(supportedPlatform),
          failureReasonValue: deferredLinkFailureReason('already_attempted'),
        );
      }
    }

    if (!isIosPlatform) {
      final attempted = await _readStorageBestEffort(_captureAttemptedKey);
      if (attempted == '1') {
        return DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.skipped,
          platformValue: deferredLinkPlatform(supportedPlatform),
          failureReasonValue: deferredLinkFailureReason('already_attempted'),
        );
      }

      await _writeStorageBestEffort(_captureAttemptedKey, '1');
    }

    final payload = await _nativeSource.readDeferredPayload(
      platform: supportedPlatform,
    );
    final resolverPayload = _normalizeText(payload?.resolverPayload);
    final fallbackStoreChannel = _normalizeText(payload?.storeChannel);

    if (resolverPayload == null && fallbackStoreChannel == null) {
      final result = DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.notCaptured,
        platformValue: deferredLinkPlatform(supportedPlatform),
        failureReasonValue: deferredLinkFailureReason('referrer_unavailable'),
      );
      if (isIosPlatform) {
        return _finalizeIosResult(
          result: result,
          failureReason: 'referrer_unavailable',
          hasResolverPayload: false,
        );
      }
      return result;
    }

    final resolverData = await _resolveWithBackend(
      platform: supportedPlatform,
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
        final consumedHash = await _readStorageBestEffort(
          _consumedReferrerHashKey,
        );
        if (consumedHash == hash) {
          final result = DeferredLinkCaptureResult(
            status: DeferredLinkCaptureStatus.notCaptured,
            platformValue: deferredLinkPlatform(supportedPlatform),
            storeChannelValue: storeChannel == null
                ? null
                : deferredLinkStoreChannel(storeChannel),
            failureReasonValue: deferredLinkFailureReason(
              'referrer_already_consumed',
            ),
          );
          if (isIosPlatform) {
            return _finalizeIosResult(
              result: result,
              failureReason: 'referrer_already_consumed',
              hasResolverPayload: true,
            );
          }
          return result;
        }

        await _writeStorageBestEffort(_consumedReferrerHashKey, hash);
      }

      final result = DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.captured,
        platformValue: deferredLinkPlatform(supportedPlatform),
        codeValue: code == null ? null : deferredLinkCode(code),
        targetPathValue: deferredLinkTargetPath(targetPath),
        storeChannelValue: storeChannel == null
            ? null
            : deferredLinkStoreChannel(storeChannel),
      );
      if (isIosPlatform) {
        await _markIosCaptureFinalized();
      }
      return result;
    }

    final result = DeferredLinkCaptureResult(
      status: DeferredLinkCaptureStatus.notCaptured,
      platformValue: deferredLinkPlatform(supportedPlatform),
      storeChannelValue: storeChannel == null
          ? null
          : deferredLinkStoreChannel(storeChannel),
      failureReasonValue: deferredLinkFailureReason(
        failureReason ?? 'resolver_not_captured',
      ),
    );
    if (isIosPlatform) {
      return _finalizeIosResult(
        result: result,
        failureReason: failureReason ?? 'resolver_not_captured',
        hasResolverPayload: resolverPayload != null,
      );
    }
    return result;
  }

  Future<String?> _readStorageBestEffort(String key) async {
    String? value;
    try {
      value = await _storage.read(key: key);
    } catch (error, stackTrace) {
      debugPrint(
        'DeferredLinkRepository storage read failed for $key: '
        '$error\n$stackTrace',
      );
    }
    return value;
  }

  Future<void> _writeStorageBestEffort(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error, stackTrace) {
      debugPrint(
        'DeferredLinkRepository storage write failed for $key: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> _deleteStorageBestEffort(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (error, stackTrace) {
      debugPrint(
        'DeferredLinkRepository storage delete failed for $key: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<int> _incrementIosTransientAttemptCount() async {
    final currentRaw = await _readStorageBestEffort(
      _iosTransientAttemptCountKey,
    );
    final currentCount = int.tryParse(currentRaw ?? '') ?? 0;
    final nextCount = currentCount + 1;
    await _writeStorageBestEffort(
      _iosTransientAttemptCountKey,
      nextCount.toString(),
    );
    return nextCount;
  }

  Future<void> _markIosCaptureFinalized() async {
    await _writeStorageBestEffort(_iosCaptureFinalizedKey, '1');
    await _deleteStorageBestEffort(_iosTransientAttemptCountKey);
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

  Future<DeferredLinkCaptureResult> _finalizeIosResult({
    required DeferredLinkCaptureResult result,
    required String failureReason,
    required bool hasResolverPayload,
  }) async {
    if (_isIosRetryableFailure(
      failureReason: failureReason,
      hasResolverPayload: hasResolverPayload,
    )) {
      final attemptCount = await _incrementIosTransientAttemptCount();
      if (attemptCount < _iosMaxTransientAttempts) {
        return result;
      }
    }

    await _markIosCaptureFinalized();
    return result;
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
