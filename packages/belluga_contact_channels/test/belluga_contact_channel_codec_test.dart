import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('channel codec parses whatsapp metadata initial messages', () {
    final channel = BellugaContactChannelCodec.channelFromJson(
      <String, dynamic>{
        'id': 'whatsapp-primary',
        'type': 'whatsapp',
        'value': '+55 (11) 99999-9999',
        'title': 'Suporte',
        'metadata': <String, dynamic>{
          'initial_messages': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'cta-1',
              'cta': 'Falar com consultor',
              'mensagem': 'Olá, quero saber mais.',
            },
          ],
        },
      },
    );

    expect(channel, isNotNull);
    expect(channel!.type, BellugaContactChannelType.whatsapp);
    expect(channel.title, 'Suporte');
    expect(channel.initialMessages, hasLength(1));
    expect(channel.initialMessages.single.id, 'cta-1');
    expect(channel.initialMessages.single.cta, 'Falar com consultor');
  });

  test('channel codec encodes whatsapp initial messages under metadata', () {
    final encoded = BellugaContactChannelCodec.channelToJson(
      BellugaContactChannel(
        id: 'whatsapp-primary',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (11) 99999-9999',
        initialMessages: const <BellugaContactInitialMessage>[
          BellugaContactInitialMessage(
            id: 'cta-1',
            cta: 'Falar com consultor',
            message: 'Olá',
          ),
        ],
      ),
    );

    expect(encoded['id'], 'whatsapp-primary');
    expect(encoded['type'], 'whatsapp');
    expect(encoded['metadata'], isA<Map<String, dynamic>>());
    final metadata = encoded['metadata'] as Map<String, dynamic>;
    expect(metadata['initial_messages'], isA<List<dynamic>>());
  });
}
