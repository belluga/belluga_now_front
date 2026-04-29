import 'package:belluga_now/infrastructure/dal/dao/invites/invites_response_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = InvitesResponseDecoder();

  test('decodeRequiredInviteDto returns dto for canonical payload', () {
    final dto = decoder.decodeRequiredInviteDto(
      _buildInvitePayload(),
      context: 'preview',
    );

    expect(dto.id, 'invite-1');
    expect(dto.eventId, 'event-1');
    expect(dto.occurrenceId, 'occurrence-1');
    expect(dto.eventName, 'Invite Event');
  });

  test('decodeRequiredInviteDto rejects non-object payload', () {
    expect(
      () => decoder.decodeRequiredInviteDto(
        'invalid',
        context: 'preview',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('expected object'),
        ),
      ),
    );
  });

  test('decodeRequiredInviteDto rejects payload missing critical fields', () {
    final payload = _buildInvitePayload()
      ..remove('event_name')
      ..remove('host_name');

    expect(
      () => decoder.decodeRequiredInviteDto(
        payload,
        context: 'preview',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('missing event_name'),
        ),
      ),
    );
  });

  test('decodeInviteDtos keeps valid entries and drops malformed ones', () {
    final decoded = decoder.decodeInviteDtos([
      _buildInvitePayload(id: 'invite-valid'),
      'invalid',
      {'event_name': 'missing-required-identifiers'},
    ]);

    expect(decoded, hasLength(1));
    expect(decoded.first.id, 'invite-valid');
  });

  test('decodeRequiredInviteDto rejects payload missing occurrence identity',
      () {
    final payload = _buildInvitePayload()..remove('occurrence_id');

    expect(
      () => decoder.decodeRequiredInviteDto(
        payload,
        context: 'preview',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('missing occurrence_id'),
        ),
      ),
    );
  });
}

Map<String, dynamic> _buildInvitePayload({
  String id = 'invite-1',
  String eventId = 'event-1',
  String occurrenceId = 'occurrence-1',
}) {
  return {
    'id': id,
    'event_id': eventId,
    'occurrence_id': occurrenceId,
    'event_name': 'Invite Event',
    'event_date': '2099-01-01T20:00:00Z',
    'event_image_url': 'https://example.com/event.png',
    'location': 'Guarapari',
    'host_name': 'Belluga',
    'message': 'Bora?',
    'tags': ['music'],
    'attendance_policy': 'free_confirmation_only',
    'inviter_candidates': [
      {
        'invite_id': id,
        'display_name': 'Invite Sender',
        'avatar_url': 'https://example.com/avatar.png',
        'status': 'pending',
        'principal_kind': 'user',
        'principal_id': 'user-1',
      }
    ],
    'inviter_principal': {
      'kind': 'user',
      'id': 'user-1',
    },
  };
}
