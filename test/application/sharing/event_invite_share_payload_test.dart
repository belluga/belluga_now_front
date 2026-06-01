import 'package:belluga_now/application/sharing/event_invite_share_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('build creates engaging copy with human-readable day and time', () {
    final payload = EventInviteSharePayloadBuilder.build(
      eventName: 'Show de Verão',
      location: 'Praia do Morro',
      eventDateTime: DateTime(2026, 3, 14, 20, 30),
      publicUri: Uri.parse('https://tenant.test/agenda/evento/show'),
    );

    expect(payload.subject, 'Convite para Show de Verão');
    expect(payload.message, contains('Bora para Show de Verão?'));
    expect(
      payload.message,
      contains('sábado, 14 de março às 20h30 em Praia do Morro'),
    );
    expect(
      payload.message,
      contains('https://tenant.test/agenda/evento/show'),
    );
    expect(payload.message, isNot(contains('2026-03-14')));
  });

  test('preview uses the same human-readable schedule language', () {
    final preview = EventInviteSharePayloadBuilder.preview(
      eventName: 'Festival',
      location: 'Centro',
      eventDateTime: DateTime(2026, 3, 15, 20),
    );

    expect(
      preview,
      'Bora para Festival? domingo, 15 de março às 20h em Centro.',
    );
  });
}
