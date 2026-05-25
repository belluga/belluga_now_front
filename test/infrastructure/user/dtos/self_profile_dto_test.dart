import 'package:belluga_now/infrastructure/user/dtos/self_profile_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SelfProfileDto maps counters, avatar, and timezone into domain', () {
    final dto = SelfProfileDto.fromJson({
      'user_id': '507f1f77bcf86cd799439011',
      'account_profile_id': '507f1f77bcf86cd799439012',
      'display_name': 'Maria',
      'bio': 'Bio persistida',
      'phone': '+55 27 99876-1234',
      'avatar_url': 'https://tenant.test/avatar.png',
      'timezone': 'America/Sao_Paulo',
      'social_score': {
        'invites_sent': '12',
        'invites_accepted': 5,
      },
      'counters': {
        'pending_invites': '4',
        'confirmed_events': 7,
      },
    });

    final profile = dto.toDomain();

    expect(profile.userId, '507f1f77bcf86cd799439011');
    expect(profile.accountProfileId, '507f1f77bcf86cd799439012');
    expect(profile.displayName, 'Maria');
    expect(profile.bio, 'Bio persistida');
    expect(profile.phone, '+55 27 99876-1234');
    expect(profile.avatarUrl, 'https://tenant.test/avatar.png');
    expect(profile.invitesSentCount, 12);
    expect(profile.invitesAcceptedCount, 5);
    expect(profile.pendingInvitesCount, 4);
    expect(profile.confirmedEventsCount, 7);
    expect(profile.timezone, 'America/Sao_Paulo');
  });

  test('SelfProfileDto normalizes empty optional values and missing counters',
      () {
    final dto = SelfProfileDto.fromJson({
      'user_id': '507f1f77bcf86cd799439011',
      'display_name': 'Sem avatar',
      'bio': '',
      'phone': '+55 27 99876-1234',
      'avatar_url': '   ',
      'timezone': '',
      'counters': const <String, dynamic>{},
    });

    final profile = dto.toDomain();

    expect(profile.accountProfileId, isEmpty);
    expect(profile.avatarUrl, isNull);
    expect(profile.invitesSentCount, 0);
    expect(profile.invitesAcceptedCount, 0);
    expect(profile.pendingInvitesCount, 0);
    expect(profile.confirmedEventsCount, 0);
    expect(profile.timezone, isNull);
  });

  test('SelfProfileDto maps social metrics from social_score, not counters',
      () {
    final dto = SelfProfileDto.fromJson({
      'user_id': '507f1f77bcf86cd799439011',
      'display_name': 'Metricas',
      'social_score': {
        'invites_sent': 9,
        'invites_accepted': '3',
      },
      'counters': {
        'pending_invites': 99,
        'confirmed_events': 88,
      },
    });

    final profile = dto.toDomain();

    expect(profile.invitesSentCount, 9);
    expect(profile.invitesAcceptedCount, 3);
    expect(profile.pendingInvitesCount, 99);
    expect(profile.confirmedEventsCount, 88);
  });
}
