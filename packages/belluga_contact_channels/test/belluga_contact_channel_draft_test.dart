import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registry resolves definition-owned capabilities without UI type logic',
      () {
    final registry = BellugaContactChannelRegistry.canonical;

    final email = registry.require(BellugaContactChannelType.email);
    final whatsapp = registry.require(BellugaContactChannelType.whatsapp);

    expect(email.canonicalLabel, 'E-mail');
    expect(email.capabilities.bubble, isFalse);
    expect(email.capabilities.messagePresets, isFalse);
    expect(whatsapp.canonicalLabel, 'WhatsApp');
    expect(whatsapp.capabilities.bubble, isTrue);
    expect(whatsapp.capabilities.messagePresets, isTrue);
  });

  test('new draft encodes draft key while persisted draft keeps server id', () {
    final newDraft = BellugaContactChannelDraft(
      draftKey: 'draft-whatsapp-support',
      type: BellugaContactChannelType.whatsapp,
      value: '+55 (27) 99999-1111',
    );
    final persistedDraft = BellugaContactChannelDraft(
      draftKey: 'persisted:channel-1',
      id: 'channel-1',
      type: BellugaContactChannelType.email,
      value: 'support@belluga.test',
    );

    expect(
      BellugaContactChannelCodec.draftToJson(newDraft),
      <String, dynamic>{
        'draft_key': 'draft-whatsapp-support',
        'type': 'whatsapp',
        'value': '+55 (27) 99999-1111',
      },
    );
    expect(
      BellugaContactChannelCodec.draftToJson(persistedDraft),
      <String, dynamic>{
        'id': 'channel-1',
        'type': 'email',
        'value': 'support@belluga.test',
      },
    );
  });

  test('bubble mutation encodes omit clear persisted and draft intents exactly',
      () {
    final cases = <BellugaContactBubbleSelectionMutation, Map<String, dynamic>>{
      const BellugaContactBubbleSelectionMutation.omit(): <String, dynamic>{},
      const BellugaContactBubbleSelectionMutation.clear(): <String, dynamic>{
        'contact_bubble_channel_id': null,
      },
      BellugaContactBubbleSelectionMutation.setPersisted('channel-1'):
          <String, dynamic>{'contact_bubble_channel_id': 'channel-1'},
      BellugaContactBubbleSelectionMutation.setDraft('draft-1'):
          <String, dynamic>{'contact_bubble_channel_draft_key': 'draft-1'},
    };

    for (final entry in cases.entries) {
      final payload = <String, dynamic>{};
      entry.key.encodeInto(payload);
      expect(payload, entry.value);
    }
  });

  test('repeatable type requires a title for every duplicate draft', () {
    final drafts = <BellugaContactChannelDraft>[
      BellugaContactChannelDraft(
        draftKey: 'email-a',
        type: BellugaContactChannelType.email,
        value: 'a@belluga.test',
      ),
      BellugaContactChannelDraft(
        draftKey: 'email-b',
        type: BellugaContactChannelType.email,
        value: 'b@belluga.test',
        title: 'Financeiro',
      ),
    ];

    expect(
      BellugaContactChannelDraftValidator.validate(drafts),
      contains('Todo E-mail repetido precisa de título.'),
    );
  });

  test('WhatsApp draft validation enforces definition-owned CTA cardinality and text limits',
      () {
    final capabilities = BellugaContactChannelRegistry.canonical
        .require(BellugaContactChannelType.whatsapp)
        .capabilities;
    final drafts = <BellugaContactChannelDraft>[
      BellugaContactChannelDraft(
        draftKey: 'whatsapp-primary',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-1111',
        initialMessages: List<BellugaContactInitialMessage>.generate(
          capabilities.maxInitialMessages + 1,
          (index) => BellugaContactInitialMessage(
            id: 'cta-$index',
            cta: 'CTA $index',
            message: 'Mensagem $index',
          ),
        ),
      ),
      BellugaContactChannelDraft(
        draftKey: 'whatsapp-secondary',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 98888-2222',
        title: 'Secundário',
        initialMessages: <BellugaContactInitialMessage>[
          BellugaContactInitialMessage(
            id: 'oversized',
            cta: List<String>.filled(
              capabilities.maxInitialMessageCtaLength + 1,
              'C',
            ).join(),
            message: List<String>.filled(
              capabilities.maxInitialMessageLength + 1,
              'M',
            ).join(),
          ),
        ],
      ),
    ];

    expect(
      BellugaContactChannelDraftValidator.validate(drafts),
      contains('WhatsApp permite no máximo ${capabilities.maxInitialMessages} CTAs.'),
    );
    expect(
      BellugaContactChannelDraftValidator.validate(drafts),
      contains(
        'As CTAs de WhatsApp precisam ter até ${capabilities.maxInitialMessageCtaLength} caracteres.',
      ),
    );
    expect(
      BellugaContactChannelDraftValidator.validate(drafts),
      contains(
        'As mensagens de WhatsApp precisam ter até ${capabilities.maxInitialMessageLength} caracteres.',
      ),
    );
  });
}
