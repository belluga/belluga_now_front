import 'package:belluga_now/domain/partners/engagement_data.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_schedule_backend.dart';

class MockAccountProfilesDatabase {
  MockAccountProfilesDatabase();

  /// Get all account profiles (artists + venues)
  List<AccountProfileModel> get allAccountProfiles => _accountProfiles;

  /// Persisted favorites in-memory to emulate storage
  final Set<String> _favoriteAccountProfileIds = {_appManagerId};

  /// App manager is always favorited by default
  static const String _appManagerId = 'app-manager';

  static final List<AccountProfileModel> _accountProfiles =
      _generateAccountProfiles();

  /// Expose favorites
  Set<String> get favoriteAccountProfileIds => _favoriteAccountProfileIds;

  /// Toggle favorite and persist in-memory
  void toggleFavorite(String accountProfileId) {
    if (accountProfileId == _appManagerId) {
      // App manager cannot be unfavorited
      return;
    }
    if (_favoriteAccountProfileIds.contains(accountProfileId)) {
      _favoriteAccountProfileIds.remove(accountProfileId);
    } else {
      _favoriteAccountProfileIds.add(accountProfileId);
    }
  }

  static List<AccountProfileModel> _generateAccountProfiles() {
    final profiles = <AccountProfileModel>[];

    // Extract artists from event seeds
    // NOTE: Commented out to show only rich mock data with engagement metrics
    /*
    final artistsMap = <String, MockArtistSeed>{};
    for (final eventSeed in MockScheduleBackend.eventSeeds) {
      for (final artist in eventSeed.artists) {
        if (!artistsMap.containsKey(artist.id)) {
          artistsMap[artist.id] = artist;
        }
      }
    }

    // Convert artists to AccountProfileModel
    for (final artist in artistsMap.values) {
      final artistId = MockScheduleBackend.generateMongoId(artist.id);

      // Find events for this artist
      final artistEventIds = <String>[];
      for (final eventSeed in MockScheduleBackend.eventSeeds) {
        if (eventSeed.artists.any((a) => a.id == artist.id)) {
          artistEventIds.add(MockScheduleBackend.generateMongoId(eventSeed.id));
        }
      }

      profiles.add(
        AccountProfileModel.fromPrimitives(
          id: artistId,
          name: artist.name,
          slug: artist.id,
          type: 'artist',
          avatarUrl: artist.avatarUrl,
          coverUrl: null, // Artists don't have cover images in current data
          bio: 'Artista talentoso apresentando shows incríveis em Guarapari.',
          tags: ['música', 'show', 'entretenimento'],
          upcomingEventIds: artistEventIds,
        ),
      );
    }
    */

    // Extract venues from MockScheduleBackend
    // Note: _eventVenues is private, so we'll need to expose it or use a different approach
    // For now, let's create some mock venues based on the events
    // We'll create venue profiles from the location data in events
    // This is a simplified approach since we can't access _eventVenues directly
    // --- RICH MOCK DATA INJECTION ---

    // 1. Partners (B2B)

    // Restaurante "Beach Club" (Full Config)
    profiles.add(AccountProfileModel.fromPrimitives(
      id: MockScheduleBackend.generateMongoId('beach-club'),
      name: 'Beach Club Guarapari',
      slug: 'beach-club',
      type: 'venue',
      avatarUrl:
          'https://images.unsplash.com/photo-1578474843222-9593bc5c30b0?w=400',
      coverUrl:
          'https://images.unsplash.com/photo-1578474843222-9593bc5c30b0?w=1200',
      bio:
          'O melhor beach club do litoral. Gastronomia, música e vibes à beira-mar.',
      tags: ['beach club', 'restaurante', 'festas', 'praia'],
      upcomingEventIds: [],
      isVerified: true,
      engagementData: const VenueEngagementData(presenceCount: 120),
      acceptedInvites: 45,
      distanceMeters: 1200,
    ));

    // Bistrô Pequeno (Minimal Config)
    profiles.add(AccountProfileModel.fromPrimitives(
      id: MockScheduleBackend.generateMongoId('bistro-pequeno'),
      name: 'Le Petit Bistrô',
      slug: 'le-petit-bistro',
      type: 'venue',
      avatarUrl:
          'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400',
      coverUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200',
      bio: 'Culinária francesa intimista no coração da cidade.',
      tags: ['bistrô', 'francês', 'jantar', 'romântico'],
      upcomingEventIds: [],
      isVerified: true,
      engagementData: const VenueEngagementData(presenceCount: 45),
      acceptedInvites: 23,
      distanceMeters: 2400,
    ));

    // Músico (DJ Residente)
    profiles.add(AccountProfileModel.fromPrimitives(
      id: MockScheduleBackend.generateMongoId('dj-residente'),
      name: 'DJ Alex Beat',
      slug: 'dj-alex-beat',
      type: 'artist',
      avatarUrl:
          'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400',
      coverUrl:
          'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=1200',
      bio: 'Residente do Beach Club. House music e vibes eletrônicas.',
      tags: ['dj', 'house', 'eletrônica', 'música'],
      upcomingEventIds: [],
      engagementData: const ArtistEngagementData(status: 'TOCANDO AGORA'),
      acceptedInvites: 87,
      distanceMeters: 1800,
    ));

    profiles.add(AccountProfileModel.fromPrimitives(
      id: MockScheduleBackend.generateMongoId('band-alt'),
      name: 'Banda Mar Aberto',
      slug: 'banda-mar-aberto',
      type: 'artist',
      avatarUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
      coverUrl:
          'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=1200',
      bio: 'Indie e MPB com clima de pôr do sol.',
      tags: ['indie', 'mpb', 'show'],
      upcomingEventIds: [],
      engagementData: const ArtistEngagementData(status: 'COMEÇA EM BREVE'),
      acceptedInvites: 54,
      distanceMeters: 3100,
    ));

    profiles.add(AccountProfileModel.fromPrimitives(
      id: MockScheduleBackend.generateMongoId('dj-night'),
      name: 'DJ Nightwave',
      slug: 'dj-nightwave',
      type: 'artist',
      avatarUrl:
          'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400',
      coverUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200',
      bio: 'Eletrônica e deep house para madrugadas intensas.',
      tags: ['eletrônica', 'house', 'dj'],
      upcomingEventIds: [],
      engagementData: const ArtistEngagementData(status: 'TOCANDO AGORA'),
      acceptedInvites: 102,
      distanceMeters: 900,
    ));

    // Guia (Experience Provider)
    profiles.add(AccountProfileModel.fromPrimitives(
      id: MockScheduleBackend.generateMongoId('guia-local'),
      name: 'Guarapari Adventures',
      slug: 'guarapari-adventures',
      type: 'experience_provider',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
      coverUrl:
          'https://images.unsplash.com/photo-1501555088652-021faa106b9b?w=1200',
      bio: 'Guias locais especializados em trilhas e mergulho.',
      tags: ['aventura', 'trilhas', 'mergulho', 'turismo'],
      upcomingEventIds: [],
      engagementData: const ExperienceEngagementData(experienceCount: 12),
      acceptedInvites: 34,
      distanceMeters: 5200,
    ));

    // 2. Users (B2C+)

    // Influencer (Nível 2)
    profiles.add(AccountProfileModel.fromPrimitives(
      id: MockScheduleBackend.generateMongoId('influencer-top'),
      name: 'Bella Lifestyle',
      slug: 'bella-lifestyle',
      type: 'influencer',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      coverUrl:
          'https://images.unsplash.com/photo-1516455207990-7a41ce80f7ee?w=1200',
      bio: 'Dicas de lifestyle, moda e os melhores points de Guarapari.',
      tags: ['lifestyle', 'moda', 'dicas', 'influencer'],
      upcomingEventIds: [],
      isVerified: true,
      engagementData: const InfluencerEngagementData(inviteCount: 150),
      acceptedInvites: 150,
      distanceMeters: 4200,
    ));

    // Curator (Nível 3)
    profiles.add(AccountProfileModel.fromPrimitives(
      id: MockScheduleBackend.generateMongoId('curadoria-local'),
      name: 'Agenda Cultural ES',
      slug: 'agenda-cultural-es',
      type: 'curator',
      avatarUrl:
          'https://images.unsplash.com/photo-1542206395-9feb3edaa68d?w=400',
      coverUrl:
          'https://images.unsplash.com/photo-1459749411177-287ce1465101?w=1200',
      bio: 'A curadoria mais completa dos eventos culturais do Espírito Santo.',
      tags: ['cultura', 'arte', 'teatro', 'agenda'],
      upcomingEventIds: [],
      engagementData:
          const CuratorEngagementData(articleCount: 50, docCount: 20),
      acceptedInvites: 92,
      distanceMeters: 3600,
    ));

    // Basic User (Nível 1 - usually not public, but added for completeness if needed)
    // profiles.add(...)

    // Add generic venues from before to maintain volume
    final mockVenues = [
      {
        'id': 'bolinhas-bar',
        'name': 'Bolinhas Bar e Restaurante',
        'address': 'Av. Des. Laurival de Almeida, Centro',
      },
      {
        'id': 'praia-das-castanheiras',
        'name': 'Praia das Castanheiras',
        'address': 'Guarapari',
      },
    ];

    for (final venue in mockVenues) {
      final venueId =
          MockScheduleBackend.generateMongoId(venue['id'] as String);

      profiles.add(
        AccountProfileModel.fromPrimitives(
          id: venueId,
          name: venue['name'] as String,
          slug: venue['id'] as String,
          type: 'venue',
          avatarUrl:
              'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400',
          coverUrl:
              'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=1200',
          bio: 'Local incrível para eventos em ${venue['address']}.',
          tags: ['venue', 'local', 'eventos'],
          upcomingEventIds: [],
          distanceMeters: 2800,
        ),
      );
    }

    // Bulk fillers to reach volume and ensure sections have variety
    final fillerCount = 45; // total >50
    final venueNames = [
      'Casa do Samba',
      'Bar do Pescador',
      'Café do Farol',
      'Mercado da Praia',
      'Quitanda do Sol',
      'Tapas Guarapari',
      'Bistrô do Morro',
      'Restaurante do Porto',
      'Churras do Mar',
      'Cantina do Centro',
    ];
    final experienceNames = [
      'Trilha das Conchas',
      'Mergulho Azul',
      'Canoa ao Pôr do Sol',
      'Passeio de Escuna',
      'Roteiro Histórico',
    ];
    final artistNames = [
      'DJ Litoral',
      'Trio do Samba',
      'Coral do Mar',
      'MC da Orla',
      'Violinista da Serra',
    ];
    final influencerNames = [
      'Vida Praiana',
      'Night Rider',
      'Foodie Capixaba',
      'Trilheiro Urbano',
      'Surf & Sun',
    ];
    final curatorNames = [
      'Curadoria Capixaba',
      'Arquivo Vivo',
      'Roteiros & Causos',
    ];

    for (var i = 0; i < fillerCount; i++) {
      final type = switch (i % 5) {
        0 => 'venue',
        1 => 'experience_provider',
        2 => 'artist',
        3 => 'influencer',
        _ => 'curator',
      };
      final slug = 'mock-partner-$i';
      final name = switch (type) {
        'venue' =>
            '${venueNames[i % venueNames.length]} ${i ~/ venueNames.length + 1}',
        'experience_provider' =>
            '${experienceNames[i % experienceNames.length]} ${i ~/ experienceNames.length + 1}',
        'artist' =>
            '${artistNames[i % artistNames.length]} ${i ~/ artistNames.length + 1}',
        'influencer' =>
            '${influencerNames[i % influencerNames.length]} ${i ~/ influencerNames.length + 1}',
        'curator' =>
            '${curatorNames[i % curatorNames.length]} ${i ~/ curatorNames.length + 1}',
        _ => 'Perfil $i',
      };
      final tags = switch (type) {
        'venue' => ['local', 'gastronomia'],
        'experience_provider' => ['praia', 'aventura'],
        'artist' => ['show', 'música'],
        'influencer' => ['lifestyle', 'baladas'],
        'curator' => ['história', 'causos'],
        _ => const <String>[],
      };

      profiles.add(
        AccountProfileModel.fromPrimitives(
          id: MockScheduleBackend.generateMongoId(slug),
          name: name,
          slug: slug,
          type: type,
          avatarUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&sig=${i + 20}',
          coverUrl:
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&sig=${i + 20}',
          bio: 'Perfil de teste para discovery.',
          tags: type == 'influencer' && i.isEven
              ? [...tags, 'baladas', 'foodie']
              : type == 'artist' && i.isOdd
                  ? [...tags, 'rock', 'samba']
                  : type == 'venue' && i % 3 == 0
                      ? [...tags, 'vista-mar', 'romântico']
                      : tags,
          upcomingEventIds: const [],
          engagementData: type == 'artist'
              ? const ArtistEngagementData(status: 'COMEÇA EM BREVE')
              : type == 'venue'
                  ? VenueEngagementData(presenceCount: 15 + (i % 30))
                  : type == 'experience_provider'
                      ? ExperienceEngagementData(experienceCount: 3 + (i % 10))
                      : type == 'influencer'
                          ? InfluencerEngagementData(inviteCount: 10 + (i % 20))
                          : CuratorEngagementData(
                              articleCount: 5 + (i % 12),
                              docCount: 3 + (i % 8),
                            ),
          acceptedInvites: 20 + i,
          distanceMeters: 500 + (i % 15) * 250,
        ),
      );
    }

    // Sync venues and artists from schedule events
    final venueMap = <String, AccountProfileModel>{};
    for (final seed in MockScheduleBackend.eventSeeds) {
      // Venue partner from event location/coords
      final venueSlug = _slugify(seed.location);
      if (!venueMap.containsKey(venueSlug)) {
        final venueName = seed.location.trim().length < 5
            ? '${seed.location.trim()} Guarapari'
            : seed.location.trim();
        venueMap[venueSlug] = AccountProfileModel.fromPrimitives(
          id: MockScheduleBackend.generateMongoId(venueSlug),
          name: venueName,
          slug: venueSlug,
          type: 'venue',
          avatarUrl: seed.thumbUrl,
          coverUrl: seed.thumbUrl,
          tags: const ['evento', 'local'],
          distanceMeters: 1800,
        );
      }
      // Artists
      for (final artist in seed.artists) {
        final artistSlug = _slugify(artist.name);
        profiles.add(
          AccountProfileModel.fromPrimitives(
            id: MockScheduleBackend.generateMongoId(artist.id),
            name: artist.name,
            slug: artistSlug,
            type: 'artist',
            avatarUrl: artist.avatarUrl,
            coverUrl: seed.thumbUrl,
            tags: const ['show', 'artista'],
            engagementData: const ArtistEngagementData(status: 'COMEÇA EM BREVE'),
            acceptedInvites: 15,
            distanceMeters: 1900,
          ),
        );
      }
    }

    profiles.addAll(venueMap.values);

    return profiles;
  }

  /// Search profiles by name or tags
  List<AccountProfileModel> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) {
    var results = allAccountProfiles;

    // Filter by type
    if (typeFilter != null) {
      results = results.where((p) => p.type == typeFilter).toList();
    }

    // Filter by query
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((p) {
        return p.name.toLowerCase().contains(lowerQuery) ||
            p.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      }).toList();
    }

    return results;
  }

  /// Get partner by slug
  AccountProfileModel? getAccountProfileBySlug(String slug) {
    try {
      return allAccountProfiles.firstWhere((p) => p.slug == slug);
    } catch (e) {
      return null;
    }
  }

  static String _slugify(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
