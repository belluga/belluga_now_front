import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_contact_channels_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'places WhatsApp CTAs and a simple exclusive bubble toggle on its channel card',
    (tester) async {
      final draft = BellugaContactChannelDraft(
        draftKey: 'draft-whatsapp-1',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-1111',
        initialMessages: const <BellugaContactInitialMessage>[
          BellugaContactInitialMessage(
            id: 'cta-1',
            cta: 'Falar com suporte',
            message: 'Olá',
          ),
        ],
      );
      BellugaContactChannelDraft? selected;
      bool? isSelected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                child: TenantAdminContactChannelsEditor(
                  drafts: <BellugaContactChannelDraft>[draft],
                  bubbleSelection:
                      const BellugaContactBubbleSelectionMutation.omit(),
                  expandedCtaDraftKey: draft.draftKey,
                  onAddChannel: (_) {},
                  onUpdateChannel: (_) {},
                  onRemoveChannel: (_) {},
                  onSelectBubble: (channel, value) {
                    selected = channel;
                    isSelected = value;
                  },
                  onToggleCtaEditor: (_) {},
                  onAddInitialMessage: (_) {},
                  onUpdateInitialMessage: (draftKey, message) {},
                  onRemoveInitialMessage: (draftKey, messageId) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('CTAs e mensagens'), findsOneWidget);
      expect(find.text('Falar com suporte'), findsOneWidget);
      expect(find.text('Ativar balão flutuante'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(RadioListTile<String>), findsNothing);
      expect(find.text('Balão Flutuante'), findsNothing);

      await tester.tap(
        find.byKey(
          const Key('tenantAdminContactBubbleToggle_draft-whatsapp-1'),
        ),
      );
      expect(selected, same(draft));
      expect(isSelected, isTrue);
    },
  );

  testWidgets(
    'mounts CTA fields only for the controller-selected WhatsApp card and disables add at its capability limit',
    (tester) async {
      final maxInitialMessages = BellugaContactChannelRegistry.canonical
          .require(BellugaContactChannelType.whatsapp)
          .capabilities
          .maxInitialMessages;
      final drafts = List<BellugaContactChannelDraft>.generate(
        BellugaContactChannelDraftValidator.maxChannels,
        (draftIndex) => BellugaContactChannelDraft(
          draftKey: 'draft-whatsapp-$draftIndex',
          type: BellugaContactChannelType.whatsapp,
          value: '+55 (27) 99999-${(1000 + draftIndex).toString()}',
          initialMessages: List<BellugaContactInitialMessage>.generate(
            maxInitialMessages,
            (messageIndex) => BellugaContactInitialMessage(
              id: 'cta-$draftIndex-$messageIndex',
              cta: 'CTA $messageIndex',
              message: 'Mensagem $messageIndex',
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                child: TenantAdminContactChannelsEditor(
                  drafts: drafts,
                  bubbleSelection:
                      const BellugaContactBubbleSelectionMutation.omit(),
                  expandedCtaDraftKey: 'draft-whatsapp-0',
                  onAddChannel: (_) {},
                  onUpdateChannel: (_) {},
                  onRemoveChannel: (_) {},
                  onSelectBubble: (_, _) {},
                  onToggleCtaEditor: (_) {},
                  onAddInitialMessage: (_) {},
                  onUpdateInitialMessage: (_, _) {},
                  onRemoveInitialMessage: (_, _) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('tenantAdminContactCta_draft-whatsapp-0_cta-0-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminContactCta_draft-whatsapp-1_cta-1-1')),
        findsNothing,
      );
      expect(
        find.byType(TextFormField),
        findsNWidgets(
          BellugaContactChannelDraftValidator.maxChannels * 2 +
              maxInitialMessages * 2,
        ),
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(
                const Key('tenantAdminContactAddCta_draft-whatsapp-0'),
              ),
            )
            .onPressed,
        isNull,
      );
    },
  );
}
