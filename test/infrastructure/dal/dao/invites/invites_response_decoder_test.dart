import 'package:belluga_now/infrastructure/dal/dao/invites/invites_response_decoder.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
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
    expect(dto.eventSlug, 'invite-event');
    expect(dto.occurrenceId, 'occurrence-1');
    expect(dto.eventName, 'Invite Event');
  });

  test('decodeRequiredInviteDto tolerates missing event slug', () {
    final dto = decoder.decodeRequiredInviteDto(
      _buildInvitePayload()..remove('event_slug'),
      context: 'preview',
    );
    final domain = dto.toDomain();

    expect(dto.eventSlug, isEmpty);
    expect(domain.eventSlug, isEmpty);
    expect(domain.eventId, 'event-1');
  });

  test('decodeRequiredInviteDto hydrates linked profiles and profile groups',
      () {
    final dto = decoder.decodeRequiredInviteDto(
      _buildInvitePayload(),
      context: 'preview',
    );
    final domain = dto.toDomain();

    expect(domain.venueAccountProfileId, 'venue-1');
    expect(domain.linkedAccountProfiles, hasLength(3));
    expect(domain.profileGroups, hasLength(2));
    expect(domain.profileGroups.first.label, 'Bandas');
    expect(
      domain.profileGroups.first.accountProfileIdValues.first.value,
      'band-1',
    );
    expect(domain.linkedAccountProfiles[1].displayName, 'Du Jorge');
    expect(domain.primaryInviter?.principal?.type, InviteInviterType.user);
    expect(domain.primaryInviter?.principal?.id, 'user-1');
  });

  test('decodeRequiredInviteDto tolerates missing event image url', () {
    final dto = decoder.decodeRequiredInviteDto(
      _buildInvitePayload()
        ..['event_image_url'] = ''
        ..['linked_account_profiles'] = [
          {
            'id': 'venue-1',
            'display_name': 'Promotion Smoke Perfil Público',
            'profile_type': 'venue',
          },
        ],
      context: 'preview',
    );
    final domain = dto.toDomain();

    expect(domain.eventImageUrl, startsWith('data:image/gif;base64,'));
    expect(domain.eventName, 'Invite Event');
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
    'event_slug': 'invite-event',
    'occurrence_id': occurrenceId,
    'event_name': 'Invite Event',
    'event_date': '2099-01-01T20:00:00Z',
    'event_image_url': 'https://example.com/event.png',
    'location': 'Guarapari',
    'host_name': 'Belluga',
    'message': 'Bora?',
    'taxonomy_terms': [
      {
        'type': 'genre',
        'value': 'music',
        'name': 'Music',
        'label': 'Music',
      },
    ],
    'linked_account_profiles': [
      {
        'id': 'venue-1',
        'display_name': 'Promotion Smoke Perfil Público',
        'profile_type': 'venue',
      },
      {
        'id': 'band-1',
        'display_name': 'Du Jorge',
        'profile_type': 'artist',
      },
      {
        'id': 'exhibitor-1',
        'display_name': 'QA Discovery Tag Sem Tags',
        'profile_type': 'exhibitor',
      },
    ],
    'profile_groups': [
      {
        'id': 'bandas',
        'label': 'Bandas',
        'order': 0,
        'account_profile_ids': ['band-1'],
      },
      {
        'id': 'expositores',
        'label': 'Expositores',
        'order': 1,
        'account_profile_ids': ['exhibitor-1'],
      },
    ],
    'venue_account_profile_id': 'venue-1',
    'attendance_policy': 'free_confirmation_only',
    'inviter_candidates': [
      {
        'invite_id': id,
        'display_name': 'Invite Sender',
        'avatar_url': 'https://example.com/avatar.png',
        'status': 'pending',
        'inviter_principal': {
          'kind': 'user',
          'id': 'user-1',
        },
      }
    ],
    'inviter_principal': {
      'kind': 'user',
      'id': 'user-1',
    },
  };
}
