import 'package:belluga_now/infrastructure/invites/dtos/invite_dto.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/mock_schedule_backend.dart';

class MockInvitesDatabase {
  MockInvitesDatabase();

  List<InviteDto> get invites => _invites;
  List<Friend> get friends => _friends;

  // Mutable storage for sent invites by event slug
  static final Map<String, List<Map<String, dynamic>>> _sentInvitesByEvent = {};

  void addSentInvite(String eventSlug, Map<String, dynamic> inviteData) {
    if (!_sentInvitesByEvent.containsKey(eventSlug)) {
      _sentInvitesByEvent[eventSlug] = [];
    }
    _sentInvitesByEvent[eventSlug]!.add(inviteData);
  }

  List<Map<String, dynamic>> getSentInvitesForEvent(String eventSlug) {
    return _sentInvitesByEvent[eventSlug] ?? [];
  }

  static final List<InviteDto> _invites = _generateInvites();

  static List<InviteDto> _generateInvites() {
    final seeds = MockScheduleBackend.eventSeeds;
    // Filter for events in the next 10 days (offsetDays <= 10)
    final upcomingSeeds =
        seeds.where((s) => s.offsetDays >= 0 && s.offsetDays <= 10).toList();
    upcomingSeeds.shuffle();
    final selectedSeeds = upcomingSeeds.take(5).toList();

    return selectedSeeds.map((seed) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final eventDate = today
          .add(Duration(days: seed.offsetDays))
          .add(Duration(hours: seed.startHour));

      // Use the same ID generation logic as MockScheduleBackend to match IDs
      final eventId = MockScheduleBackend.generateMongoId(seed.id);

      return InviteDto(
        id: 'invite-${seed.id}',
        eventId: eventId,
        eventName: seed.title,
        eventDate: eventDate.toIso8601String(),
        eventImageUrl: seed.thumbUrl,
        location: seed.location,
        hostName: seed.artists.isNotEmpty ? seed.artists.first.name : 'Belluga',
        message: 'Bora nessa? Vai ser irado!',
        tags: [seed.type.name, 'belluga'],
        inviterName: 'Carla Dias',
        inviterAvatarUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
        additionalInviters: const ['João', 'Maria'],
      );
    }).toList();
  }

  static final List<Friend> _friends = [
    Friend(
      idValue: FriendIdValue()..parse('carol-viajante'),
      nameValue: TitleValue()..parse('Carol Viajante'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?w=200'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Vocês foram a 4 experiencias de oceano juntos'),
    ),
    Friend(
      idValue: FriendIdValue()..parse('leo-fotografo'),
      nameValue: TitleValue()..parse('Leo Fotografo'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Amigo destaque em fotografia submarina'),
    ),
    Friend(
      idValue: FriendIdValue()..parse('bia-surfer'),
      nameValue: TitleValue()..parse('Bia Surfer'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?auto=format&fit=crop&w=400&q=80'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Curte remadas noturnas e aulas de SUP'),
    ),
    Friend(
      idValue: FriendIdValue()..parse('igor-tech'),
      nameValue: TitleValue()..parse('Igor Tech'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Sempre topa experiencias com storytelling'),
    ),
    Friend(
      idValue: FriendIdValue()..parse('mila-yogi'),
      nameValue: TitleValue()..parse('Mila Yogi'),
      avatarValue: FriendAvatarValue()
        ..parse(
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200'),
      matchLabelValue: FriendMatchLabelValue()
        ..parse('Parceira dos retiros de bem-estar'),
    ),
  ];
}
