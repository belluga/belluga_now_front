import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/mock_schedule_backend.dart';

class MockPartnersDatabase {
  MockPartnersDatabase();

  /// Get all partners (artists + venues)
  List<PartnerModel> get allPartners => _partners;

  static final List<PartnerModel> _partners = _generatePartners();

  static List<PartnerModel> _generatePartners() {
    final partners = <PartnerModel>[];

    // Extract artists from event seeds
    final artistsMap = <String, MockArtistSeed>{};
    for (final eventSeed in MockScheduleBackend.eventSeeds) {
      for (final artist in eventSeed.artists) {
        if (!artistsMap.containsKey(artist.id)) {
          artistsMap[artist.id] = artist;
        }
      }
    }

    // Convert artists to PartnerModel
    for (final artist in artistsMap.values) {
      final artistId = MockScheduleBackend.generateMongoId(artist.id);

      // Find events for this artist
      final artistEventIds = <String>[];
      for (final eventSeed in MockScheduleBackend.eventSeeds) {
        if (eventSeed.artists.any((a) => a.id == artist.id)) {
          artistEventIds.add(MockScheduleBackend.generateMongoId(eventSeed.id));
        }
      }

      partners.add(
        PartnerModel.fromPrimitives(
          id: artistId,
          name: artist.name,
          slug: artist.id,
          type: PartnerType.artist,
          avatarUrl: artist.avatarUrl,
          coverUrl: null, // Artists don't have cover images in current data
          bio: 'Artista talentoso apresentando shows incríveis em Guarapari.',
          tags: ['música', 'show', 'entretenimento'],
          upcomingEventIds: artistEventIds,
        ),
      );
    }

    // Extract venues from MockScheduleBackend
    // Note: _eventVenues is private, so we'll need to expose it or use a different approach
    // For now, let's create some mock venues based on the events
    // We'll create venue partners from the location data in events
    // This is a simplified approach since we can't access _eventVenues directly
    final mockVenues = [
      {
        'id': 'american-grill',
        'name': 'American Grill',
        'address': 'Guarapari',
      },
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
      {
        'id': 'praia-do-morro',
        'name': 'Praia do Morro',
        'address': 'Guarapari',
      },
      {
        'id': 'centro-cultural',
        'name': 'Centro Cultural de Guarapari',
        'address': 'Centro, Guarapari',
      },
    ];

    for (final venue in mockVenues) {
      final venueId =
          MockScheduleBackend.generateMongoId(venue['id'] as String);

      // Find events at this venue
      final venueEventIds = <String>[];
      for (final eventSeed in MockScheduleBackend.eventSeeds) {
        // We can't directly match venues, so we'll distribute events across venues
        venueEventIds.add(MockScheduleBackend.generateMongoId(eventSeed.id));
      }

      partners.add(
        PartnerModel.fromPrimitives(
          id: venueId,
          name: venue['name'] as String,
          slug: venue['id'] as String,
          type: PartnerType.venue,
          avatarUrl:
              'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=400',
          coverUrl:
              'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=1200',
          bio: 'Local incrível para eventos em ${venue['address']}.',
          tags: ['venue', 'local', 'eventos'],
          upcomingEventIds:
              venueEventIds.take(3).toList(), // Limit to 3 events per venue
        ),
      );
    }

    return partners;
  }

  /// Search partners by name or tags
  List<PartnerModel> searchPartners({
    String? query,
    PartnerType? typeFilter,
  }) {
    var results = allPartners;

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
  PartnerModel? getPartnerBySlug(String slug) {
    try {
      return allPartners.firstWhere((p) => p.slug == slug);
    } catch (e) {
      return null;
    }
  }
}
