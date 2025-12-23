import 'package:belluga_now/domain/schedule/event_action_types.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_action_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_item_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/thumb_dto.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:get_it/get_it.dart';

class MockScheduleBackend implements ScheduleBackendContract {
  MockScheduleBackend();

  static const Duration _defaultEventDuration = Duration(hours: 3);
  List<EventDTO>? _cachedEvents;
  static const Duration _assumedLiveDuration = Duration(hours: 3);

  @override
  Future<EventSummaryDTO> fetchSummary() async {
    final events = await fetchEvents();
    final items = events
        .map(
          (event) => EventSummaryItemDTO(
            dateTimeStart: event.dateTimeStart,
            color: _getTypeColor(event.type.id),
          ),
        )
        .toList();

    return EventSummaryDTO(items: items);
  }

  /// Generates a stable 24-character hex MongoDB ObjectId from a string seed
  static String generateMongoId(String seed) {
    // Use hashCode to generate a stable number from the seed
    final hash = seed.hashCode.abs();
    // Create a 24-character hex string
    final hexString = hash.toRadixString(16).padLeft(24, '0');
    // Ensure it's exactly 24 characters
    return hexString.substring(0, 24);
  }

  String _getTypeColor(String typeId) {
    if (typeId == _concertType.id) return _concertType.color ?? '#000000';
    if (typeId == _workshopType.id) return _workshopType.color ?? '#000000';
    return '#000000';
  }

  @override
  Future<List<EventDTO>> fetchEvents() async {
    return _loadEvents();
  }

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String? searchQuery,
  }) async {
    final events = await _loadEvents();
    final now = DateTime.now();
    final query = searchQuery?.toLowerCase().trim();
    const radiusMeters = 50000.0;

    bool isHappeningNow(EventDTO event) {
      final start = DateTime.parse(event.dateTimeStart);
      final end = start.add(_defaultEventDuration);
      return (start.isBefore(now) || start.isAtSameMomentAs(now)) &&
          (now.isBefore(end) || now.isAtSameMomentAs(end));
    }

    final timeFiltered = events.where((event) {
      final start = DateTime.parse(event.dateTimeStart);
      final happeningNow = isHappeningNow(event);

      final inTimeBucket = showPastOnly
          ? start.isBefore(now) && !happeningNow
          : happeningNow || start.isAfter(now) || start.isAtSameMomentAs(now);

      if (!inTimeBucket) return false;

      if (query == null || query.isEmpty) return true;

      final titleMatch = event.title.toLowerCase().contains(query);
      final contentMatch = event.content.toLowerCase().contains(query);
      final locationMatch = event.location.toLowerCase().contains(query);
      final artistMatch = event.artists.any(
        (artist) => artist.name.toLowerCase().contains(query),
      );

      return titleMatch || contentMatch || locationMatch || artistMatch;
    }).toList();

    final locationFiltered = _filterWithinRadiusIfAvailable(
      timeFiltered,
      radiusMeters: radiusMeters,
    );

    locationFiltered.sort((a, b) {
      final aStart = DateTime.parse(a.dateTimeStart);
      final bStart = DateTime.parse(b.dateTimeStart);
      return showPastOnly ? bStart.compareTo(aStart) : aStart.compareTo(bStart);
    });

    await Future.delayed(const Duration(seconds: 1));

    final startIndex = (page - 1) * pageSize;
    if (startIndex >= locationFiltered.length) {
      return EventPageDTO(events: const [], hasMore: false);
    }

    final pageEvents =
        locationFiltered.skip(startIndex).take(pageSize).toList(growable: false);
    final hasMore = startIndex + pageSize < locationFiltered.length;

    return EventPageDTO(events: pageEvents, hasMore: hasMore);
  }

  List<EventDTO> _filterWithinRadiusIfAvailable(
    List<EventDTO> input, {
    required double radiusMeters,
  }) {
    if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      return input;
    }
    final userCoordinate =
        GetIt.I.get<UserLocationRepositoryContract>().userLocationStreamValue.value;
    if (userCoordinate == null) {
      return input;
    }

    final withinRadius = <EventDTO>[];
    for (final event in input) {
      final lat = event.latitude;
      final lon = event.longitude;
      if (lat == null || lon == null) {
        continue;
      }
      final distance = haversineDistanceMeters(
        lat1: userCoordinate.latitude,
        lon1: userCoordinate.longitude,
        lat2: lat,
        lon2: lon,
      );
      if (distance <= radiusMeters) {
        withinRadius.add(event);
      }
    }

    // Fallback: if nothing is inside the radius, keep the original list.
    return withinRadius.isNotEmpty ? withinRadius : input;
  }

  Future<List<EventDTO>> _loadEvents() async {
    if (_cachedEvents != null) {
      return _cachedEvents!;
    }

    final venues = _selectEventVenuesForCurrentTenant();
    final seeds = _buildSeedsWithPast();
    final events = List<EventDTO>.generate(
      seeds.length,
      (index) {
        final venue = venues[index % venues.length];
        return seeds[index].toDto(_today, venue);
      },
    )..sort((a, b) => DateTime.parse(a.dateTimeStart)
        .compareTo(DateTime.parse(b.dateTimeStart)));

    _cachedEvents = events;
    return events;
  }

  List<EventVenue> _selectEventVenuesForCurrentTenant() {
    String? hostname;
    try {
      hostname = GetIt.I.get<AppData>().hostname;
    } catch (_) {
      hostname = null;
    }

    final tenantSubdomain =
        hostname != null ? _tenantSubdomainFromHostname(hostname) : null;

    final List<EventVenue> selected;
    if (tenantSubdomain == 'alfredochaves') {
      selected = _eventVenues
          .where((venue) => venue.id.startsWith('alfredo-'))
          .toList(growable: false);
    } else {
      selected = _eventVenues
          .where((venue) => !venue.id.startsWith('alfredo-'))
          .toList(growable: false);
    }

    return selected.isNotEmpty ? selected : _eventVenues;
  }

  String? _tenantSubdomainFromHostname(String hostname) {
    final landlord = BellugaConstants.landlordDomain;
    if (hostname == landlord) return null;
    final suffix = '.$landlord';
    if (!hostname.endsWith(suffix)) return null;
    return hostname.substring(0, hostname.length - suffix.length);
  }

  List<MockEventSeed> _buildSeedsWithPast() {
    final seeds = <MockEventSeed>[...eventSeeds];

    // Ensure at least two "happening now" events (start before now, still within duration)
    final liveCopies = liveNowSeedsForToday();
    seeds.addAll(liveCopies.map(
      (seed) => seed.copyWith(
        receivedInvites: _sampleInvites(seed.id),
      ),
    ));

    for (var daysBack = 1; daysBack <= 3; daysBack++) {
      seeds.addAll(
        eventSeeds.map(
          (seed) => seed.copyWith(
            id: '${seed.id}-past$daysBack',
            offsetDays: -daysBack,
          ),
        ),
      );
    }
    return seeds;
  }

  List<Map<String, dynamic>> _sampleInvites(String eventId) {
    return [
      {
        'id': '${eventId}_inv1',
        'event_id': eventId,
        'event_name': 'Convite especial',
        'event_date': DateTime.now().toIso8601String(),
        'event_image_url':
            'https://images.unsplash.com/photo-1492724441997-5dc865305da7?w=800',
        'location': 'Guarapari',
        'host_name': 'Equipe Belluga',
        'message': 'Bora colar agora?',
        'tags': ['ao vivo'],
        'inviter_name': 'Maria',
        'inviter_avatar_url':
            'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=200',
        'additional_inviters': ['João'],
      }
    ];
  }

  static List<MockEventSeed> liveNowSeedsForToday() {
    final now = DateTime.now();
    final liveStartHour = (now.hour - 1).clamp(0, 23);
    final liveStartHour2 = (now.hour - 2).clamp(0, 23);
    final liveSeeds = eventSeeds.take(2).toList();
    final liveCopies = <MockEventSeed>[];
    if (liveSeeds.isNotEmpty) {
      liveCopies.add(
        liveSeeds[0].copyWith(
          id: '${liveSeeds[0].id}-live',
          offsetDays: 0,
          startHour: liveStartHour,
          durationMinutes: _assumedLiveDuration.inMinutes,
        ),
      );
    }
    if (liveSeeds.length > 1) {
      liveCopies.add(
        liveSeeds[1].copyWith(
          id: '${liveSeeds[1].id}-live2',
          offsetDays: 0,
          startHour: liveStartHour2,
          durationMinutes: _assumedLiveDuration.inMinutes,
        ),
      );
    }
    return liveCopies;
  }

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Generate stable fake MongoDB IDs for event types
  static final String _concertTypeId = '507f1f77bcf86cd799439011';
  static final String _workshopTypeId = '507f1f77bcf86cd799439012';

  static final _concertType = EventTypeDTO(
    id: _concertTypeId,
    name: 'Show',
    slug: 'show',
    description: 'Apresentacoes ao vivo',
    icon: 'music',
    color: '#FF4FA0E3',
  );

  static final _workshopType = EventTypeDTO(
    id: _workshopTypeId,
    name: 'Oficina',
    slug: 'oficina',
    description: 'Atividades guiadas com especialistas',
    icon: 'workshop',
    color: '#FFE80D5D',
  );

  static const List<EventVenue> _eventVenues = [
    EventVenue(
      id: 'american-grill',
      name: 'American Grill',
      address: 'Guarapari',
      latitude: -20.6600241,
      longitude: -40.502093,
    ),
    EventVenue(
      id: 'alfredo-adega-restaurante',
      name: 'Adega Restaurante',
      address: 'Matilde, Alfredo Chaves - ES',
      latitude: -20.555612,
      longitude: -40.816068,
    ),
    EventVenue(
      id: 'alfredo-restaurante-prainha',
      name: 'Restaurante Prainha',
      address: 'Matilde, Alfredo Chaves - ES',
      latitude: -20.556303,
      longitude: -40.81689,
    ),
    EventVenue(
      id: 'alfredo-restaurante-boldrini',
      name: 'Restaurante Boldrini',
      address: 'Centro, Alfredo Chaves - ES',
      latitude: -20.634608,
      longitude: -40.751046,
    ),
    EventVenue(
      id: 'alfredo-padaria-confeitaria-boldrini',
      name: 'Padaria e Confeitaria Boldrini',
      address: 'Centro, Alfredo Chaves - ES',
      latitude: -20.634671,
      longitude: -40.751134,
    ),
    EventVenue(
      id: 'alfredo-padaria-ki-pao',
      name: 'Padaria Ki-pão',
      address: 'Centro, Alfredo Chaves - ES',
      latitude: -20.634985,
      longitude: -40.750269,
    ),
    EventVenue(
      id: 'alfredo-sitio-recanto-das-videiras',
      name: 'Sitio Recanto das Videiras',
      address: 'Alfredo Chaves - ES',
      latitude: -20.5524902,
      longitude: -40.8487666,
    ),
    EventVenue(
      id: 'bolinhas-bar',
      name: 'Bolinhas Bar e Restaurante',
      address: 'Av. Des. Laurival de Almeida, Centro',
      latitude: -20.6739006,
      longitude: -40.4980227,
    ),
    EventVenue(
      id: 'box-mineiro',
      name: 'Box Mineiro',
      address: 'Rua Henrique Coutinho, Centro',
      latitude: -20.6703232,
      longitude: -40.4965388,
    ),
    EventVenue(
      id: 'barraca-do-marcelo',
      name: 'Barraca do Marcelo',
      address: 'Praia de Meaípe',
      latitude: -20.7381371,
      longitude: -40.5430268,
    ),
    EventVenue(
      id: 'le-cave',
      name: 'Le Cave',
      address: 'Enseada Azul',
      latitude: -20.6520423,
      longitude: -40.4859819,
    ),
    EventVenue(
      id: 'donatello',
      name: 'Donatello Restaurante e Pizzaria',
      address: 'Avenida Maria de Lourdes Carvalho Dantas',
      latitude: -20.6534829,
      longitude: -40.4894282,
    ),
    EventVenue(
      id: 'deck',
      name: 'Deck',
      address: 'Centro',
      latitude: -20.6720688,
      longitude: -40.4976626,
    ),
    EventVenue(
      id: 'kibe-lanches',
      name: 'Kibe Lanches',
      address: 'Centro',
      latitude: -20.671917,
      longitude: -40.4979096,
    ),
    EventVenue(
      id: 'herois-burger',
      name: 'Heróis Burger',
      address: 'Guarapari',
      latitude: -20.6513284,
      longitude: -40.4792761,
    ),
    EventVenue(
      id: 'bistro-sal-e-tal',
      name: 'Bistro Sal e Tal',
      address: 'Guarapari',
      latitude: -20.7217392,
      longitude: -40.5241274,
    ),
    EventVenue(
      id: 'benfica',
      name: 'Benfica',
      address: 'Rua Henrique Coutinho, Centro',
      latitude: -20.6708241,
      longitude: -40.496421,
    ),
    EventVenue(
      id: 'cia-comida',
      name: 'Cia & Comida',
      address: 'Guarapari',
      latitude: -20.6703032,
      longitude: -40.4984612,
    ),
    EventVenue(
      id: 'gostoso',
      name: 'Gostoso',
      address: 'Guarapari',
      latitude: -20.6731777,
      longitude: -40.4982096,
    ),
    EventVenue(
      id: 'free-dog',
      name: 'Free Dog Pizzaria e Lanchonete',
      address: 'Avenida José Ferreira Ferro',
      latitude: -20.6562124,
      longitude: -40.4922658,
    ),
    EventVenue(
      id: 'restaurante-boqueirao',
      name: 'Restaurante Boqueirão',
      address: 'Meaípe',
      latitude: -20.7416995,
      longitude: -40.5359065,
    ),
  ];

  static const List<_VenueSeed> _venueSeeds = [
    _VenueSeed(
      id: 'ika-pokeria',
      name: 'Ika Pokeria',
      latitude: -20.6695,
      longitude: -40.5001,
      imageUrl:
          'https://midias.agazeta.com.br/2025/01/16/ika-pokeria-em-guarapari-2572826-article.jpeg',
    ),
    _VenueSeed(
      id: 'boteco-do-caranguejo',
      name: 'Boteco do Caranguejo',
      latitude: -20.7155,
      longitude: -40.5075,
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSHAVidLyKH-GBf9T_jW6R6zdnni5vtjmpDlQ&s',
    ),
    _VenueSeed(
      id: 'gaeta',
      name: 'Gaeta',
      latitude: -20.7102,
      longitude: -40.5009,
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTgF2W1xAyyrEesALs6f8mqnluPTOcw3i8bEQ&s',
    ),
    _VenueSeed(
      id: 'maratimbas',
      name: 'Maratimbas Botequim',
      latitude: -20.6715,
      longitude: -40.503,
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQdl7PT4B9Z7iewK8pdZ7_1jwZAfXOqyWhrWA&s',
    ),
    _VenueSeed(
      id: 'speranza',
      name: 'Cervejaria Speranza',
      latitude: -20.666,
      longitude: -40.501,
      imageUrl: 'https://www.folhaonline.es/wp-content/uploads/2024/10/speranza.jpeg',
    ),
    _VenueSeed(
      id: 'boteco-do-urso',
      name: 'Boteco do Urso',
      latitude: -20.67,
      longitude: -40.499,
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSYPzswg5Eypa7CAgIwVCcP0iFz3I0uX0wqlA&s',
    ),
    _VenueSeed(
      id: 'buena-villa',
      name: 'Buena Villa',
      latitude: -20.672,
      longitude: -40.502,
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTosEiod8kYkvKITqeE9t_Owgpzl5cyQ02r3g&s',
    ),
    _VenueSeed(
      id: 'o-pereira',
      name: 'O Pereira',
      latitude: -20.668,
      longitude: -40.498,
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRwICsOs06WR1BvhsHeOVNk8ruTx3NPlOdBZA&s',
    ),
    _VenueSeed(
      id: 'canecao',
      name: 'Canecão',
      latitude: -20.665,
      longitude: -40.497,
      imageUrl:
          'https://lh3.googleusercontent.com/p/AF1QipOWeyFJSzh1wnxNdsFAqVzjF9W7aX9P9rrXYCMg=w1280-h1280-no',
    ),
    _VenueSeed(
      id: 'carvoeiro',
      name: 'Carvoeiro',
      latitude: -20.676,
      longitude: -40.505,
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTmUjJIoM8hmN9e41vk5OnnHgpzFuiDIN6fvw&s',
    ),
    _VenueSeed(
      id: 'bells-pub',
      name: 'Bells Pub',
      latitude: -20.674,
      longitude: -40.504,
      imageUrl:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSU0_SB-vemGmwiIfw6q62hP-SvFwGupfXDiQ&s',
    ),
    _VenueSeed(
      id: 'food-hall',
      name: 'Food Hall',
      latitude: -20.667,
      longitude: -40.5,
      imageUrl:
          'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/19/62/f1/87/melhor-sunset-nao-ha.jpg?w=900&h=500&s=1',
    ),
    _VenueSeed(
      id: 'mex',
      name: 'Mex',
      latitude: -20.669,
      longitude: -40.506,
      imageUrl:
          'https://www.mexguarapari.com.br/upload_arquivos/fotos/11/pequeno/bar_restaurante_salseiro_guarapari-01.jpg',
    ),
  ];

  static const List<_ArtistSeed> _artistSeeds = [
    _ArtistSeed(name: 'Yuri Dias'),
    _ArtistSeed(name: 'Ananda Torres'),
    _ArtistSeed(name: 'Du Jorge'),
    _ArtistSeed(name: 'Mariana Muller'),
    _ArtistSeed(name: 'Anfrisio Lima'),
    _ArtistSeed(name: 'Som Caipira'),
    _ArtistSeed(name: 'Marcos Paulo'),
    _ArtistSeed(name: 'Alex Rangel'),
    _ArtistSeed(name: 'Miguel Costa'),
    _ArtistSeed(name: 'Gabriel Rezzende'),
    _ArtistSeed(name: 'Raddar 027'),
    _ArtistSeed(name: 'Elias Miúdo'),
    _ArtistSeed(name: 'Alecs Rodriguez'),
    _ArtistSeed(name: 'Go Back'),
    _ArtistSeed(name: 'Flavio Pestana'),
    _ArtistSeed(name: 'Cleber Lacerda'),
    _ArtistSeed(name: 'Mary Di'),
    _ArtistSeed(name: 'Power Trio'),
  ];

  static final List<MockEventSeed> eventSeeds = _buildGeneratedSeeds();

  static List<MockEventSeed> _buildGeneratedSeeds() {
    final seeds = <MockEventSeed>[];
    var artistCursor = 0;
    const totalDays = 10;

    for (var day = 0; day < totalDays; day++) {
      final eventsForDay = 3 + (day % 4); // 3–6 events/day
      final venueStart = day % _venueSeeds.length;
      final venuesForDay = List.generate(
        eventsForDay,
        (idx) => _venueSeeds[(venueStart + idx) % _venueSeeds.length],
      );

      for (var i = 0; i < venuesForDay.length; i++) {
        final venue = venuesForDay[i];
        final artist = _artistSeeds[artistCursor % _artistSeeds.length];
        artistCursor += 1;

        final id = '${venue.id}-${_slugify(artist.name)}-d$day';
        final startHour = 18 + (i % 3) * 2; // 18, 20, 22 rotation

        seeds.add(MockEventSeed(
          id: id,
          type: _concertType,
          title: artist.name,
          content: 'Show de ${artist.name} no ${venue.name}.',
          location: venue.name,
          latitude: venue.latitude,
          longitude: venue.longitude,
          thumbUrl: venue.imageUrl,
          offsetDays: day,
          startHour: startHour,
          durationMinutes: 120,
          artists: [
            MockArtistSeed(
              id: 'artist-${_slugify(artist.name)}',
              name: artist.name,
              avatarUrl: venue.imageUrl,
              highlight: true,
            ),
          ],
          actionLabel: 'Reservar mesa',
          actionUrl: 'https://example.com/$id',
          actionColor: '#FFE80D5D',
          tags: [venue.name.toLowerCase()],
        ));
      }
    }

    return seeds;
  }

  static String _slugify(String input) {
    final lower = input.toLowerCase();
    final slug = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }

}

class EventVenue {
  const EventVenue({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
}

class MockEventSeed {
  const MockEventSeed({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.thumbUrl,
    required this.offsetDays,
    required this.startHour,
    this.durationMinutes = 90,
    required this.artists,
    required this.actionLabel,
    required this.actionUrl,
    required this.actionColor,
    this.isConfirmed = false,
    this.totalConfirmed = 0,
    this.receivedInvites = const [],
    this.sentInvites = const [],
    this.friendsGoing = const [],
    this.tags = const [],
  });

  final String id;
  final EventTypeDTO type;
  final String title;
  final String content;
  final String location;
  final double latitude;
  final double longitude;
  final String thumbUrl;
  final int offsetDays;
  final int startHour;
  final int durationMinutes;
  final List<MockArtistSeed> artists;
  final String actionLabel;
  final String actionUrl;
  final String actionColor;
  final bool isConfirmed;
  final int totalConfirmed;
  final List<Map<String, dynamic>> receivedInvites;
  final List<Map<String, dynamic>> sentInvites;
  final List<Map<String, dynamic>> friendsGoing;
  final List<String> tags;

  MockEventSeed copyWith({
    String? id,
    int? offsetDays,
    int? startHour,
    int? durationMinutes,
    List<String>? tags,
    List<Map<String, dynamic>>? receivedInvites,
  }) {
    return MockEventSeed(
      id: id ?? this.id,
      type: type,
      title: title,
      content: content,
      location: location,
      latitude: latitude,
      longitude: longitude,
      thumbUrl: thumbUrl,
      offsetDays: offsetDays ?? this.offsetDays,
      startHour: startHour ?? this.startHour,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      artists: artists,
      actionLabel: actionLabel,
      actionUrl: actionUrl,
      actionColor: actionColor,
      isConfirmed: isConfirmed,
      totalConfirmed: totalConfirmed,
      receivedInvites: receivedInvites ?? this.receivedInvites,
      sentInvites: sentInvites,
      friendsGoing: friendsGoing,
      tags: tags ?? this.tags,
    );
  }

  EventDTO toDto(DateTime today, EventVenue venue) {
    final start = today
        .add(Duration(days: offsetDays))
        .add(Duration(hours: startHour))
        .toIso8601String();
    final end = today
        .add(Duration(days: offsetDays))
        .add(Duration(hours: startHour, minutes: durationMinutes))
        .toIso8601String();

    return EventDTO(
      id: MockScheduleBackend.generateMongoId(id),
      slug: id,
      type: type,
      title: title,
      content: content,
      dateTimeStart: start,
      dateTimeEnd: end,
      location: location.isNotEmpty ? location : venue.name,
      latitude: latitude,
      longitude: longitude,
      thumb: ThumbDTO(
        type: 'image',
        data: {'url': thumbUrl},
      ),
      artists: artists.map((a) => a.toDto()).toList(),
      actions: [
        EventActionDTO(
          label: actionLabel,
          openIn: EventActionTypes.external.name,
          externalUrl: actionUrl,
          color: actionColor,
        ),
      ],
      isConfirmed: isConfirmed,
      totalConfirmed: totalConfirmed,
      friendsGoing: friendsGoing,
      receivedInvites: receivedInvites,
      sentInvites: sentInvites,
      tags: tags,
    );
  }
}

class MockArtistSeed {
  const MockArtistSeed({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.highlight = false,
    this.genres = const [],
  });

  final String id;
  final String name;
  final String avatarUrl;
  final bool highlight;
  final List<String> genres;

  EventArtistDTO toDto() {
    return EventArtistDTO(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      highlight: highlight,
      genres: genres,
    );
  }
}

class _VenueSeed {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String imageUrl;

  const _VenueSeed({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
  });
}

class _ArtistSeed {
  final String name;

  const _ArtistSeed({
    required this.name,
  });
}
