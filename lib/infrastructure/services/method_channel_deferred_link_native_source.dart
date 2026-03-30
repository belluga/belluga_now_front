import 'package:belluga_now/infrastructure/services/deferred_link_native_payload.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_native_source_contract.dart';
import 'package:flutter/services.dart';

class MethodChannelDeferredLinkNativeSource
    implements DeferredLinkNativeSourceContract {
  MethodChannelDeferredLinkNativeSource({
    required MethodChannel channel,
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<DeferredLinkNativePayload?> readInstallReferrerPayload() async {
    DeferredLinkNativePayload? payload;
    try {
      final raw = await _channel.invokeMethod<Object?>('getInstallReferrer');
      payload = _normalizePayload(raw);
    } on PlatformException {
      payload = null;
    } on MissingPluginException {
      payload = null;
    }
    return payload;
  }

  DeferredLinkNativePayload? _normalizePayload(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final installReferrer = _normalizeText(
      raw['install_referrer'] ?? raw['referrer'],
    );
    final storeChannel = _resolveStoreChannel(raw, installReferrer);
    if (installReferrer == null && storeChannel == null) {
      return null;
    }
    return DeferredLinkNativePayload(
      installReferrer: installReferrer,
      storeChannel: storeChannel,
    );
  }

  String? _resolveStoreChannel(
    Map<Object?, Object?> rawPayload,
    String? installReferrer,
  ) {
    final directChannel = _normalizeText(rawPayload['store_channel']);
    if (directChannel != null) {
      return directChannel;
    }
    if (installReferrer == null) {
      return null;
    }

    final normalizedReferrer = installReferrer.startsWith('?')
        ? installReferrer.substring(1)
        : installReferrer;
    String? resolvedChannel;
    try {
      final query = Uri.splitQueryString(normalizedReferrer);
      resolvedChannel = _normalizeText(
        query['store_channel'] ?? query['utm_source'] ?? query['channel'],
      );
    } catch (_) {
      resolvedChannel = null;
    }
    return resolvedChannel;
  }

  String? _normalizeText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}
