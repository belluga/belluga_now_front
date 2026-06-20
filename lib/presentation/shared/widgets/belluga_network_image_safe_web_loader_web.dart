import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List> loadBellugaSafeWebImageBytes(String url) async {
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError(
      'Failed to fetch image bytes from "$url" (HTTP ${response.status}).',
    );
  }

  final buffer = await response.arrayBuffer().toDart;
  return Uint8List.view(buffer.toDart);
}

bool shouldUseBellugaSafeWebImageLoader(String url) {
  final normalized = url.trim();
  if (normalized.isEmpty) {
    return false;
  }

  final uri = Uri.tryParse(normalized);
  if (uri == null) {
    return false;
  }

  if (!uri.hasScheme) {
    return true;
  }

  final base = Uri.base;
  return uri.scheme == base.scheme &&
      uri.host == base.host &&
      _effectivePort(uri) == _effectivePort(base);
}

int _effectivePort(Uri uri) {
  if (uri.hasPort) {
    return uri.port;
  }

  switch (uri.scheme) {
    case 'http':
      return 80;
    case 'https':
      return 443;
    default:
      return -1;
  }
}
