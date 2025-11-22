import 'package:belluga_now/infrastructure/invites/dtos/invite_dto.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

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

  static final List<InviteDto> _invites = [
    InviteDto(
      id: 'sun-chasers',
      eventId: 'event-123',
      eventName: 'Sun Chasers Beach Session',
      eventDate: '2025-11-18T16:30:00.000',
      eventImageUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=900',
      location: 'Praia da Bacutia',
      hostName: 'Jade e Lucas',
      message:
          'Vem curtir um fim de tarde com jam acustica e rodada de mate gelado. A galera da yoga vai colar.',
      tags: const [
        'sunset',
        'musica ao vivo',
        'friends only',
      ],
      inviterName: 'Jade Carvalho',
      inviterAvatarUrl:
          'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=200',
      additionalInviters: const [
        'Lucas Andrade',
        'Duda Lima',
      ],
    ),
    InviteDto(
      id: 'rooftop-jazz',
      eventId: 'event-456',
      eventName: 'Rooftop Jazz & Wine',
      eventDate: '2025-11-20T20:00:00.000',
      eventImageUrl:
          'https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=900',
      location: 'Sky Lounge Bar',
      hostName: 'Jazz Collective',
      message:
          'Noite de jazz experimental com vista para a cidade. Traga seu vinho favorito (rolha free).',
      tags: const [
        'jazz',
        'wine',
        'rooftop',
        'nightlife',
      ],
      inviterName: 'Jazz Collective',
      inviterAvatarUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200',
      additionalInviters: const [],
    ),
    InviteDto(
      id: 'sunday-brunch',
      eventId: 'event-789',
      eventName: 'Sunday Garden Brunch',
      eventDate: '2025-11-23T10:00:00.000',
      eventImageUrl:
          'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=900',
      location: 'Jardim Botânico',
      hostName: 'Café do Jardim',
      message:
          'Brunch colaborativo no jardim. Traga uma fruta ou bebida para compartilhar. Música ambiente e toalhas de piquenique.',
      tags: const [
        'brunch',
        'picnic',
        'nature',
        'sunday vibes',
      ],
      inviterName: 'Ana Silva',
      inviterAvatarUrl:
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
      additionalInviters: const [
        'Pedro Santos',
      ],
    ),
    InviteDto(
      id: 'reef-research-night',
      eventId: 'event-457', // Added eventId
      eventName: 'Noite Lab Marinho + Reef Night Dive',
      eventDate: '2025-11-21T19:00:00.000',
      eventImageUrl:
          'https://images.unsplash.com/photo-1455659817273-f96807779a8a?w=900',
      location: 'Instituto Mar Limpo',
      hostName: 'Instituto Mar Limpo',
      message:
          'Sessao pocket sobre especies locais, seguida de mergulho noturno guiado. Equipamentos inclusos.',
      tags: const [
        'mergulho',
        'educacao ambiental',
        'noite',
      ],
      inviterName: 'Instituto Mar Limpo',
      inviterAvatarUrl:
          'https://images.unsplash.com/photo-1458253756246-1e4ed949191b?w=200',
      additionalInviters: const [],
    ),
    InviteDto(
      id: 'moon-dinner',
      eventId: 'event-458', // Added eventId
      eventName: 'Jantar Colaborativo Lua Cheia',
      eventDate: '2025-11-25T20:00:00.000',
      eventImageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900',
      location: 'Deck Solar das Castanheiras',
      hostName: 'Chef Marina',
      message:
          'Cada convidado leva um prato autoral com ingredientes do mar. Playlist de lo-fi e telescopio aberto.',
      tags: const [
        'gastronomia do mar',
        'lua cheia',
        'intimista',
      ],
      inviterName: 'Chef Marina',
      inviterAvatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      additionalInviters: const [
        'Equipe Solar',
      ],
    ),
  ];

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
            'https://images.unsplash.com/photo-1544723795-3fb77d388754?w=200'),
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
