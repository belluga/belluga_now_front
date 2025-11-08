import 'package:belluga_now/domain/invites/invite_inviter.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_partner_summary.dart';
import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class MockInvitesDatabase {
  const MockInvitesDatabase();

  List<InviteModel> get invites => _invites;
  List<Friend> get friends => _friends;

  static final List<InviteModel> _invites = [
    InviteModel(
      id: 'sun-chasers',
      eventName: 'Sun Chasers Beach Session',
      eventDateTime: DateTime(2025, 11, 18, 16, 30),
      eventImageUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=900',
      location: 'Praia da Bacutia',
      hostName: 'Jade e Lucas',
      message:
          'Vem curtir um fim de tarde com jam acustica e rodada de mate gelado. A galera da yoga vai colar.',
      tags: [
        'sunset',
        'musica ao vivo',
        'friends only',
      ],
      inviters: [
        InviteInviter(
          type: InviteInviterType.user,
          name: 'Jade Carvalho',
          avatarUrl:
              'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=200',
        ),
        InviteInviter(
          type: InviteInviterType.partner,
          name: 'Sitio do Cafe Feliz',
          partner: InvitePartnerSummary(
            id: 'sitio-do-cafe-feliz',
            nameValue: InvitePartnerNameValue()..parse('Sitio do Cafe Feliz'),
            type: InvitePartnerType.mercadoProducer,
            taglineValue: InvitePartnerTaglineValue()
              ..parse('Cafes especiais e produtos da roca'),
            heroImageValue: InvitePartnerHeroImageValue()
              ..parse(
                'https://images.unsplash.com/photo-1504753793650-d4a2b783c15e?auto=format&fit=crop&w=600&q=80',
              ),
            logoImageValue: InvitePartnerLogoImageValue()
              ..parse(
                'https://images.unsplash.com/photo-1511920170033-f8396924c348?auto=format&fit=crop&w=400&q=80',
              ),
          ),
        ),
        InviteInviter(
          type: InviteInviterType.user,
          name: 'Lucas Andrade',
        ),
        InviteInviter(
          type: InviteInviterType.user,
          name: 'Duda Lima',
        ),
      ],
      inviterName: 'Jade Carvalho',
      inviterAvatarUrl:
          'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=200',
      additionalInviters: [
        'Lucas Andrade',
        'Duda Lima',
      ],
    ),
    InviteModel(
      id: 'reef-research-night',
      eventName: 'Noite Lab Marinho + Reef Night Dive',
      eventDateTime: DateTime(2025, 11, 21, 19, 0),
      eventImageUrl:
          'https://images.unsplash.com/photo-1455659817273-f96807779a8a?w=900',
      location: 'Instituto Mar Limpo',
      hostName: 'Instituto Mar Limpo',
      message:
          'Sessao pocket sobre especies locais, seguida de mergulho noturno guiado. Equipamentos inclusos.',
      tags: [
        'mergulho',
        'educacao ambiental',
        'noite',
      ],
      inviters: [
        InviteInviter(
          type: InviteInviterType.partner,
          name: 'Instituto Mar Limpo',
          avatarUrl:
              'https://images.unsplash.com/photo-1458253756246-1e4ed949191b?w=200',
          partner: InvitePartnerSummary(
            id: 'instituto-mar-limpo',
            nameValue: InvitePartnerNameValue()..parse('Instituto Mar Limpo'),
            type: InvitePartnerType.mercadoProducer,
            taglineValue: InvitePartnerTaglineValue()
              ..parse('Parceiro ambiental capixaba'),
            heroImageValue: InvitePartnerHeroImageValue()
              ..parse(
                'https://images.unsplash.com/photo-1458253756246-1e4ed949191b?w=900',
              ),
          ),
        ),
      ],
      inviterName: 'Instituto Mar Limpo',
      inviterAvatarUrl:
          'https://images.unsplash.com/photo-1458253756246-1e4ed949191b?w=200',
      additionalInviters: [],
    ),
    InviteModel(
      id: 'moon-dinner',
      eventName: 'Jantar Colaborativo Lua Cheia',
      eventDateTime: DateTime(2025, 11, 25, 20, 0),
      eventImageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900',
      location: 'Deck Solar das Castanheiras',
      hostName: 'Chef Marina',
      message:
          'Cada convidado leva um prato autoral com ingredientes do mar. Playlist de lo-fi e telescopio aberto.',
      tags: [
        'gastronomia do mar',
        'lua cheia',
        'intimista',
      ],
      inviters: [
        InviteInviter(
          type: InviteInviterType.partner,
          name: 'Chef Marina Experiencias',
          partner: InvitePartnerSummary(
            id: 'chef-marina',
            nameValue: InvitePartnerNameValue()
              ..parse('Chef Marina Experiencias'),
            type: InvitePartnerType.mercadoProducer,
            taglineValue: InvitePartnerTaglineValue()
              ..parse('Vivencias gastronomicas a beira-mar'),
            heroImageValue: InvitePartnerHeroImageValue()
              ..parse(
                'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=900',
              ),
          ),
        ),
        InviteInviter(
          type: InviteInviterType.user,
          name: 'Equipe Solar',
        ),
      ],
      inviterName: 'Chef Marina',
      inviterAvatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      additionalInviters: [
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
