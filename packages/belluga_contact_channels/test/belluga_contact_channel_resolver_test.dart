import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves whatsapp channel into canonical wa.me deeplink with text', () {
    final resolution = BellugaContactChannelResolver.resolveChannel(
      BellugaContactChannel(
        id: 'whatsapp-primary',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (11) 99999-9999',
      ),
      prefilledMessage: 'Olá Belluga',
    );

    expect(resolution, isNotNull);
    expect(
      resolution!.uri.toString(),
      'https://wa.me/5511999999999?text=Ol%C3%A1%20Belluga',
    );
    expect(resolution.normalizedTarget, '5511999999999');
  });

  test('resolves wa.me input by preserving normalized target only', () {
    final resolution = BellugaContactChannelResolver.resolveRaw(
      type: BellugaContactChannelType.whatsapp,
      rawValue: 'https://wa.me/5511999999999',
    );

    expect(resolution, isNotNull);
    expect(resolution!.normalizedTarget, '5511999999999');
    expect(resolution.uri.toString(), 'https://wa.me/5511999999999');
  });

  test('fails closed for invalid whatsapp target', () {
    final resolution = BellugaContactChannelResolver.resolveRaw(
      type: BellugaContactChannelType.whatsapp,
      rawValue: 'Belluga suporte',
    );

    expect(resolution, isNull);
  });

  test('resolves email contact into mailto uri with body', () {
    final resolution = BellugaContactChannelResolver.resolveRaw(
      type: BellugaContactChannelType.email,
      rawValue: 'contato@belluga.io',
      prefilledMessage: 'Olá suporte',
    );

    expect(resolution, isNotNull);
    expect(
      resolution!.uri.toString(),
      'mailto:contato%40belluga.io?body=Ol%C3%A1%20suporte',
    );
  });

  test('channel exposes canonical icon token by type', () {
    final email = BellugaContactChannel(
      id: 'email-primary',
      type: BellugaContactChannelType.email,
      value: 'contato@belluga.io',
    );
    final whatsapp = BellugaContactChannel(
      id: 'whatsapp-primary',
      type: BellugaContactChannelType.whatsapp,
      value: '+55 11 99999-9999',
    );

    expect(email.iconToken, BellugaContactIconToken.emailOutlined);
    expect(whatsapp.iconToken, BellugaContactIconToken.whatsapp);
    expect(email.isBubbleEligible, isFalse);
    expect(whatsapp.isBubbleEligible, isTrue);
  });
}
