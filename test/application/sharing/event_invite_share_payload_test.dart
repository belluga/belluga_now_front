import 'package:belluga_now/application/sharing/event_invite_share_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildInvitation creates response copy with invite link only', () {
    final payload = EventInviteSharePayloadBuilder.buildInvitation(
      eventName: 'Show de Verão',
      location: 'Praia do Morro',
      eventScheduleLabel: 'Sáb, 14 mar · 20h30',
      inviteUri: Uri.parse('https://tenant.test/invite?code=SHARE-CODE'),
      inviterName: 'Bruna',
      participantGroups: const [
        (
          label: 'Bandas',
          names: ['Du Jorge', 'QA Discovery Tag Várias Tags'],
        ),
        (
          label: 'Expositores',
          names: [
            'Artesanato Central',
            'Agro Sul',
            'Casa Norte',
          ],
        ),
      ],
    );

    expect(payload.subject, 'Convite para Show de Verão');
    expect(
      payload.message,
      startsWith('Bruna te convidou para Show de Verão.'),
    );
    expect(
      payload.message,
      contains('\nSáb, 14 mar · 20h30\nPraia do Morro\n'),
    );
    expect(payload.message, contains('Bandas: Du Jorge, QA Discovery Tag'));
    expect(payload.message,
        contains('Expositores: Artesanato Central, Agro Sul, e mais 1'));
    expect(payload.message, contains('Responder ao convite:'));
    expect(
      payload.message,
      contains('https://tenant.test/invite?code=SHARE-CODE'),
    );
    expect(payload.message, isNot(contains('Detalhes:')));
    expect(payload.message, isNot(contains('Como chegar:')));
    expect(payload.message, isNot(contains('/mapa')));
    expect(payload.message, isNot(contains('2026-03-14')));
  });

  test('buildPublicShare creates neutral public event copy', () {
    final payload = EventInviteSharePayloadBuilder.buildPublicShare(
      eventName: 'Show de Verão',
      location: 'Praia do Morro',
      eventScheduleLabel: 'Sáb, 14 mar · 20h30',
      publicUri: Uri.parse('https://tenant.test/agenda/evento/show'),
    );

    expect(payload.subject, 'Show de Verão');
    expect(payload.message, startsWith('Show de Verão'));
    expect(
      payload.message,
      contains('\nSáb, 14 mar · 20h30\nPraia do Morro\n'),
    );
    expect(payload.message, contains('Ver evento:'));
    expect(
      payload.message,
      contains('https://tenant.test/agenda/evento/show'),
    );
    expect(payload.message, isNot(contains('Convite para')));
    expect(payload.message, isNot(contains('te convidou')));
    expect(payload.message, isNot(contains('Responder ao convite:')));
  });

  test('preview uses the same human-readable schedule language', () {
    final preview = EventInviteSharePayloadBuilder.preview(
      eventName: 'Festival',
      location: 'Centro',
      eventScheduleLabel: 'Dom, 15 mar · 20h',
      inviterName: 'Bruna',
    );

    expect(
      preview,
      'Bruna te convidou para Festival. Dom, 15 mar · 20h em Centro.',
    );
  });
}
