import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

typedef SystemShareLauncher = Future<void> Function(ShareParams params);
typedef ExternalUrlLauncher = Future<bool> Function(
  Uri uri, {
  required LaunchMode mode,
});

final class PublicShareLauncher {
  PublicShareLauncher._();

  static Future<void> launchSystemShare(
    ShareParams params, {
    SystemShareLauncher? launcher,
  }) async {
    if (launcher != null) {
      await launcher(params);
      return;
    }
    await SharePlus.instance.share(params);
  }

  static Future<void> launchWhatsAppOrSystemShare({
    required String text,
    required String subject,
    SystemShareLauncher? fallbackShareLauncher,
    ExternalUrlLauncher? externalUrlLauncher,
  }) async {
    final launcher = externalUrlLauncher ?? _launchExternalUrl;
    if (await _tryLaunchExternalUrl(launcher, whatsappUriForText(text))) {
      return;
    }
    if (await _tryLaunchExternalUrl(launcher, webWhatsappUriForText(text))) {
      return;
    }
    await launchSystemShare(
      ShareParams(text: text, subject: subject),
      launcher: fallbackShareLauncher,
    );
  }

  static Uri whatsappUriForText(String text) {
    return Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'text': text},
    );
  }

  static Uri webWhatsappUriForText(String text) {
    return Uri.https('wa.me', '/', {'text': text});
  }

  static Future<bool> _tryLaunchExternalUrl(
    ExternalUrlLauncher launcher,
    Uri uri,
  ) async {
    try {
      return await launcher(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _launchExternalUrl(
    Uri uri, {
    required LaunchMode mode,
  }) {
    return launchUrl(uri, mode: mode);
  }
}
