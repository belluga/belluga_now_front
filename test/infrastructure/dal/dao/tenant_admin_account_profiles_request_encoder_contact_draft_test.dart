import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_account_profiles_request_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const encoder = TenantAdminAccountProfilesRequestEncoder();

  test('update omits bubble fields when mutation intent is omit', () {
    final payload = encoder.encodeUpdateAccountProfile(
      displayName: 'Only name changed',
      bubbleSelection: const BellugaContactBubbleSelectionMutation.omit(),
    );

    expect(payload, <String, dynamic>{'display_name': 'Only name changed'});
  });

  test('update clears bubble pointer with explicit nullable field', () {
    final payload = encoder.encodeUpdateAccountProfile(
      bubbleSelection: const BellugaContactBubbleSelectionMutation.clear(),
    );

    expect(payload, <String, dynamic>{'contact_bubble_channel_id': null});
  });

  test(
    'update removes a persisted selected WhatsApp atomically with an explicit clear',
    () {
      final payload = encoder.encodeUpdateAccountProfile(
        contactChannelDrafts: <BellugaContactChannelDraft>[],
        bubbleSelection: const BellugaContactBubbleSelectionMutation.clear(),
      );

      expect(payload['contact_channels'], isEmpty);
      expect(payload['contact_bubble_channel_id'], isNull);
      expect(payload.containsKey('contact_bubble_channel_draft_key'), isFalse);
    },
  );

  test(
    'create encodes new channel draft and selects it atomically by draft key',
    () {
      final payload = encoder.encodeCreateAccountProfile(
        accountId: 'account-1',
        profileType: 'partner',
        displayName: 'Ananda',
        contactChannelDrafts: <BellugaContactChannelDraft>[
          BellugaContactChannelDraft(
            draftKey: 'draft-whatsapp-1',
            type: BellugaContactChannelType.whatsapp,
            value: '+55 (27) 99999-1111',
            initialMessages: const <BellugaContactInitialMessage>[
              BellugaContactInitialMessage(
                id: 'cta-1',
                cta: 'Falar agora',
                message: 'Olá',
              ),
            ],
          ),
        ],
        bubbleSelection: BellugaContactBubbleSelectionMutation.setDraft(
          'draft-whatsapp-1',
        ),
      );

      expect(payload['contact_bubble_channel_id'], isNull);
      expect(payload['contact_bubble_channel_draft_key'], 'draft-whatsapp-1');
      expect(payload['contact_channels'], <Map<String, dynamic>>[
        <String, dynamic>{
          'draft_key': 'draft-whatsapp-1',
          'type': 'whatsapp',
          'value': '+55 (27) 99999-1111',
          'metadata': <String, dynamic>{
            'initial_messages': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'cta-1',
                'cta': 'Falar agora',
                'mensagem': 'Olá',
              },
            ],
          },
        },
      ]);
    },
  );
}
