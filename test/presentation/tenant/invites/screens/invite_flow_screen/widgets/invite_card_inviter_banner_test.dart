import 'package:belluga_now/domain/invites/invite_inviter.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_sender_display_name_candidate_value.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/invite_card_inviter_banner.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/widgets/inviter_pill.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders resolved unknown sender as Alguém', (tester) async {
    final invite = buildInviteModelFromPrimitives(
      id: 'invite-1',
      eventId: 'event-1',
      eventName: 'Invite Event',
      eventDateTime: DateTime.utc(2026, 1, 1),
      eventImageUrl: 'https://example.com/event.png',
      location: 'Guarapari',
      hostName: 'Belluga',
      message: 'Bora?',
      tags: const <String>['music'],
      inviters: <InviteInviter>[
        InviteInviter(
          inviteIdValue: InviteInviterIdValue()..parse('invite-1'),
          type: InviteInviterType.user,
          nameValue: InviteSenderDisplayNameCandidateValue()..parse(''),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InviteCardInviterBanner(invite: invite, isPreview: false),
        ),
      ),
    );

    expect(find.text('Alguém'), findsOneWidget);
  });

  testWidgets('composes the exact unknown-sender invitation sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InviterPill(inviter: 'Alguém', extraInviters: 0)),
      ),
    );

    expect(find.text('Alguém te convidou.'), findsOneWidget);
  });
}
