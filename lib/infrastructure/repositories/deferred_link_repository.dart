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
    bool Function()? isAndroid,
    DeferredLinkBackendContract? backend,
    DeferredLinkNativeSourceContract? nativeSource,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _isAndroid = isAndroid ??
            (() {
              if (kIsWeb) {
                return false;
              }
              return Platform.isAndroid;
            }),
        _backend = backend ?? LaravelDeferredLinkBackend(),
        _nativeSource = nativeSource ??
            MethodChannelDeferredLinkNativeSource(
              channel: channel ?? const MethodChannel(_channelName),
            );

  static const String _channelName = 'com.belluga_now/deferred_link';
  static const String _captureAttemptedKey = 'deferred_link_capture_attempted';
  static const String _consumedReferrerHashKey =
      'deferred_link_consumed_referrer_hash';

  final FlutterSecureStorage _storage;
  final bool Function() _isAndroid;
  final DeferredLinkBackendContract _backend;
  final DeferredLinkNativeSourceContract _nativeSource;

  @override
  Future<DeferredLinkCaptureResult> captureFirstOpenInviteCode() async {
    if (!_isAndroid()) {
      return DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.skipped,
        failureReasonValue: deferredLinkFailureReason(
          'unsupported_platform',
        ),
      );
    }

    final attempted = await _storage.read(key: _captureAttemptedKey);
    if (attempted == '1') {
      return DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.skipped,
        failureReasonValue: deferredLinkFailureReason('already_attempted'),
      );
    }

    await _storage.write(key: _captureAttemptedKey, value: '1');

    final payload = await _nativeSource.readInstallReferrerPayload();
    final installReferrer = _normalizeText(payload?.installReferrer);
    final fallbackStoreChannel = _normalizeText(payload?.storeChannel);

    final resolverData = await _resolveWithBackend(
      installReferrer: installReferrer,
      fallbackStoreChannel: fallbackStoreChannel,
    );

    final status = _normalizeText(resolverData.status);
    final code = _normalizeText(resolverData.code);
    final targetPath = _normalizeTargetPath(
          resolverData.targetPath,
        ) ??
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
      if (installReferrer != null) {
        final hash = sha256.convert(utf8.encode(installReferrer)).toString();
        final consumedHash = await _storage.read(key: _consumedReferrerHashKey);
        if (consumedHash == hash) {
          return DeferredLinkCaptureResult(
            status: DeferredLinkCaptureStatus.notCaptured,
            storeChannelValue: storeChannel == null
                ? null
                : deferredLinkStoreChannel(storeChannel),
            failureReasonValue:
                deferredLinkFailureReason('referrer_already_consumed'),
          );
        }

        await _storage.write(key: _consumedReferrerHashKey, value: hash);
      }

      return DeferredLinkCaptureResult(
        status: DeferredLinkCaptureStatus.captured,
        codeValue: code == null ? null : deferredLinkCode(code),
        targetPathValue: deferredLinkTargetPath(targetPath),
        storeChannelValue: storeChannel == null
            ? null
            : deferredLinkStoreChannel(storeChannel),
      );
    }

    return DeferredLinkCaptureResult(
      status: DeferredLinkCaptureStatus.notCaptured,
      storeChannelValue:
          storeChannel == null ? null : deferredLinkStoreChannel(storeChannel),
      failureReasonValue: deferredLinkFailureReason(
        failureReason ?? 'resolver_not_captured',
      ),
    );
  }

  Future<DeferredLinkResolutionDto> _resolveWithBackend({
    String? installReferrer,
    String? fallbackStoreChannel,
  }) async {
    DeferredLinkResolutionDto resolution;
    try {
      resolution = await _backend.resolveDeferredLink(
        platform: 'android',
        installReferrer: installReferrer,
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
