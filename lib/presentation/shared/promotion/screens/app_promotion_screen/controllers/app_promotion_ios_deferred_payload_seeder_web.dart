import 'dart:js_interop';

import 'package:web/web.dart' as web;

const _clipboardPrefix = 'belluga_now_deferred_link_v1:';

Future<bool> seedIosDeferredPayloadToClipboard(String payload) async {
  final normalized = payload.trim();
  if (normalized.isEmpty) {
    return false;
  }

  try {
    await web.window.navigator.clipboard
        .writeText('$_clipboardPrefix$normalized')
        .toDart;
    return true;
  } catch (_) {
    return false;
  }
}
