import 'dart:async';

import 'package:belluga_now/application/rich_text/safe_rich_html.dart';
import 'package:url_launcher/url_launcher.dart';

typedef PublicRichTextUrlLauncher =
    Future<bool> Function(
      Uri uri, {
      required LaunchMode mode,
      required String webOnlyWindowName,
    });

final class PublicRichTextLinkController {
  PublicRichTextLinkController({PublicRichTextUrlLauncher? launcher})
    : _launcher = launcher ?? _defaultLauncher;

  final PublicRichTextUrlLauncher _launcher;
  final StreamController<void> _failureEffects =
      StreamController<void>.broadcast(sync: true);
  bool _launching = false;
  bool _disposed = false;

  Stream<void> get failureEffects => _failureEffects.stream;
  bool get isLaunching => _launching;

  Future<void> launch(String? raw) async {
    if (_disposed || _launching || raw == null) return;
    final uri = SafeRichHtml.canonicalExplicitHttpsUri(raw);
    if (uri == null) return;

    _launching = true;
    try {
      final opened = await _launcher(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened && !_disposed) _failureEffects.add(null);
    } catch (_) {
      if (!_disposed) _failureEffects.add(null);
    } finally {
      _launching = false;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _failureEffects.close();
  }

  static Future<bool> _defaultLauncher(
    Uri uri, {
    required LaunchMode mode,
    required String webOnlyWindowName,
  }) => launchUrl(uri, mode: mode, webOnlyWindowName: webOnlyWindowName);
}
