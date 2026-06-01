import 'package:belluga_now/presentation/shared/sharing/public_share_launcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test('whatsappUriForText builds a native WhatsApp URI with encoded text', () {
    final uri = PublicShareLauncher.whatsappUriForText('Bora? Ola & mapa');

    expect(uri.scheme, 'whatsapp');
    expect(uri.host, 'send');
    expect(uri.queryParameters['text'], 'Bora? Ola & mapa');
  });

  test('webWhatsappUriForText builds a wa.me fallback URL with encoded text',
      () {
    final uri = PublicShareLauncher.webWhatsappUriForText('Bora? Ola & mapa');

    expect(uri.scheme, 'https');
    expect(uri.host, 'wa.me');
    expect(uri.path, '/');
    expect(uri.queryParameters['text'], 'Bora? Ola & mapa');
  });

  test('launchWhatsAppOrSystemShare skips fallback when WhatsApp launches',
      () async {
    final fallbackCalls = <ShareParams>[];
    final launchedUris = <Uri>[];

    await PublicShareLauncher.launchWhatsAppOrSystemShare(
      text: 'Mensagem',
      subject: 'Assunto',
      externalUrlLauncher: (uri, {required mode}) async {
        launchedUris.add(uri);
        expect(mode, LaunchMode.externalApplication);
        return true;
      },
      fallbackShareLauncher: (params) async {
        fallbackCalls.add(params);
      },
    );

    expect(launchedUris, [PublicShareLauncher.whatsappUriForText('Mensagem')]);
    expect(fallbackCalls, isEmpty);
  });

  test('launchWhatsAppOrSystemShare tries wa.me before system share fallback',
      () async {
    final launchedUris = <Uri>[];
    final fallbackCalls = <ShareParams>[];

    await PublicShareLauncher.launchWhatsAppOrSystemShare(
      text: 'Mensagem',
      subject: 'Assunto',
      externalUrlLauncher: (uri, {required mode}) async {
        launchedUris.add(uri);
        expect(mode, LaunchMode.externalApplication);
        return launchedUris.length == 2;
      },
      fallbackShareLauncher: (params) async {
        fallbackCalls.add(params);
      },
    );

    expect(launchedUris, [
      PublicShareLauncher.whatsappUriForText('Mensagem'),
      PublicShareLauncher.webWhatsappUriForText('Mensagem'),
    ]);
    expect(fallbackCalls, isEmpty);
  });

  test('launchWhatsAppOrSystemShare falls back when all URL launches fail',
      () async {
    final fallbackCalls = <ShareParams>[];

    await PublicShareLauncher.launchWhatsAppOrSystemShare(
      text: 'Mensagem',
      subject: 'Assunto',
      externalUrlLauncher: (uri, {required mode}) async => false,
      fallbackShareLauncher: (params) async {
        fallbackCalls.add(params);
      },
    );

    expect(fallbackCalls, hasLength(1));
    expect(fallbackCalls.single.text, 'Mensagem');
    expect(fallbackCalls.single.subject, 'Assunto');
  });

  test('launchWhatsAppOrSystemShare falls back when URL launchers throw',
      () async {
    final fallbackCalls = <ShareParams>[];

    await PublicShareLauncher.launchWhatsAppOrSystemShare(
      text: 'Mensagem',
      subject: 'Assunto',
      externalUrlLauncher: (uri, {required mode}) async {
        throw StateError('blocked');
      },
      fallbackShareLauncher: (params) async {
        fallbackCalls.add(params);
      },
    );

    expect(fallbackCalls, hasLength(1));
  });
}
