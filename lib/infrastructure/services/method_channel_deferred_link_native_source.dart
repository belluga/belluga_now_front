import 'package:belluga_now/infrastructure/services/deferred_link_native_payload.dart';
import 'package:belluga_now/infrastructure/services/deferred_link_native_source_contract.dart';
import 'package:flutter/services.dart';

class MethodChannelDeferredLinkNativeSource
    implements DeferredLinkNativeSourceContract {
  MethodChannelDeferredLinkNativeSource({required MethodChannel channel})
    : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<DeferredLinkNativePayload?> readDeferredPayload({
    required String platform,
  }) async {
    final methodName = switch (platform) {
      'android' => 'getInstallReferrer',
      'ios' => 'getDeferredLinkPasteboardPayload',
      _ => null,
    };
    if (methodName == null) {
      return null;
    }

    DeferredLinkNativePayload? payload;
    try {
      final raw = await _channel.invokeMethod<Object?>(methodName);
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

    final resolverPayload = _normalizeText(
      raw['resolver_payload'] ??
          raw['payload'] ??
          raw['install_referrer'] ??
          raw['referrer'],
    );
    final storeChannel = _resolveStoreChannel(raw, resolverPayload);
    if (resolverPayload == null && storeChannel == null) {
      return null;
    }
    return DeferredLinkNativePayload(
      resolverPayload: resolverPayload,
      storeChannel: storeChannel,
    );
  }

  String? _resolveStoreChannel(
    Map<Object?, Object?> rawPayload,
    String? resolverPayload,
  ) {
    final directChannel = _normalizeText(rawPayload['store_channel']);
    if (directChannel != null) {
      return directChannel;
    }
    if (resolverPayload == null) {
      return null;
    }

    final normalizedPayload = resolverPayload.startsWith('?')
        ? resolverPayload.substring(1)
        : resolverPayload;
    String? resolvedChannel;
    try {
      final query = Uri.splitQueryString(normalizedPayload);
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
