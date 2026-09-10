import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves distinct profile and party types when serializing', () {
    final dto = InviteDto.fromJson({
      'id': 'invite-1',
      'event_id': 'event-1',
      'occurrence_id': 'occurrence-1',
      'counterpart_preview': [
        {
          'id': 'profile-1',
          'display_name': 'Casa de Testes',
          'profile_type': 'venue',
          'party_type': 'organization',
        },
      ],
    });

    final counterpart =
        (dto.toJson()['counterpart_preview'] as List<Object?>).single
            as Map<String, dynamic>;

    expect(counterpart['profile_type'], 'venue');
    expect(counterpart['party_type'], 'organization');
  });
}
