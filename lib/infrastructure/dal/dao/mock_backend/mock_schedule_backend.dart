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

    bool isHappeningNow(EventDTO event) {
      final start = DateTime.parse(event.dateTimeStart);
      final end = start.add(_defaultEventDuration);
      return (start.isBefore(now) || start.isAtSameMomentAs(now)) &&
          (now.isBefore(end) || now.isAtSameMomentAs(end));
    }

    final filtered = events.where((event) {
      final start = DateTime.parse(event.dateTimeStart);
      final happeningNow = isHappeningNow(event);

      final inTimeBucket = showPastOnly
          ? start.isBefore(now) && !happeningNow
          : happeningNow || start.isAfter(now) || start.isAtSameMomentAs(now);

      if (!inTimeBucket) return false;

      if (query == null || query.isEmpty) return true;

      final titleMatch = event.title.toLowerCase().contains(query);
      final contentMatch = event.content.toLowerCase().contains(query);
      final artistMatch = event.artists.any(
        (artist) => artist.name.toLowerCase().contains(query),
      );

      return titleMatch || contentMatch || artistMatch;
    }).toList();

    filtered.sort((a, b) {
      final aStart = DateTime.parse(a.dateTimeStart);
      final bStart = DateTime.parse(b.dateTimeStart);
      return showPastOnly ? bStart.compareTo(aStart) : aStart.compareTo(bStart);
    });

    await Future.delayed(const Duration(seconds: 1));

    final startIndex = (page - 1) * pageSize;
    if (startIndex >= filtered.length) {
      return EventPageDTO(events: const [], hasMore: false);
    }

    final pageEvents =
        filtered.skip(startIndex).take(pageSize).toList(growable: false);
    final hasMore = startIndex + pageSize < filtered.length;

    return EventPageDTO(events: pageEvents, hasMore: hasMore);
  }

  Future<List<EventDTO>> _loadEvents() async {
    if (_cachedEvents != null) {
      return _cachedEvents!;
    }

    final seeds = _buildSeedsWithPast();
    final events = List<EventDTO>.generate(
      seeds.length,
      (index) {
        final venue = _eventVenues[index % _eventVenues.length];
        return seeds[index].toDto(_today, venue);
      },
    )..sort((a, b) => DateTime.parse(a.dateTimeStart)
        .compareTo(DateTime.parse(b.dateTimeStart)));

    _cachedEvents = events;
    return events;
  }

  List<MockEventSeed> _buildSeedsWithPast() {
    final seeds = <MockEventSeed>[...eventSeeds];

    // Ensure at least two "happening now" events (start before now, still within duration)
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
    seeds.addAll(liveCopies);

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

  static final List<MockEventSeed> eventSeeds = [
    // Day 0
    MockEventSeed(
      id: 'event-day0-morning-flow',
      type: _workshopType,
      title: 'Morning Flow Yoga',
      content:
          'Sessao matinal a beira-mar focada em respiracao e alongamentos para comecar o dia.',
      location: 'Deck Praia do Morro',
      latitude: -20.6634,
      longitude: -40.4976,
      thumbUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
      offsetDays: 0,
      startHour: 8,
      durationMinutes: 75,
      artists: const [
        MockArtistSeed(
          id: 'artist-marina-luz',
          name: 'Instrutora Marina Luz',
          avatarUrl:
              'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Reservar vaga',
      actionUrl: 'https://example.com/morning-flow',
      actionColor: '#FFE80D5D',
      isConfirmed: false,
      totalConfirmed: 12,
      friendsGoing: [
        {
          'id': 'friend-1',
          'display_name': 'Ana Clara',
          'avatar_url':
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        },
        {
          'id': 'friend-2',
          'display_name': 'Pedro Silva',
          'avatar_url':
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
        },
      ],
    ),
    MockEventSeed(
      id: 'event-day0-street-art',
      type: _workshopType,
      title: 'Street Art Jam',
      content:
          'Sessao colaborativa de arte urbana com orientacao de artistas locais.',
      location: 'Beco Criativo',
      latitude: -20.6708,
      longitude: -40.5013,
      thumbUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=80',
      offsetDays: 0,
      startHour: 11,
      durationMinutes: 120,
      artists: const [
        MockArtistSeed(
          id: 'artist-nina-ruas',
          name: 'Nina Ruas',
          avatarUrl:
              'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=200',
        ),
        MockArtistSeed(
          id: 'artist-tarsila-urb',
          name: 'Coletivo Tarsila',
          avatarUrl:
              'https://images.unsplash.com/photo-1473830394358-91588751b241?w=200',
        ),
      ],
      actionLabel: 'Garantir tinta',
      actionUrl: 'https://example.com/street-art-jam',
      actionColor: '#FFE80D5D',
      receivedInvites: [
        {
          'id': 'invite-1',
          'event_name': 'Street Art Jam',
          'event_date': '2025-11-21T11:00:00.000',
          'event_image_url':
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=80',
          'location': 'Beco Criativo',
          'host_name': 'Nina Ruas',
          'message': 'Vamos pintar juntos!',
          'tags': ['arte', 'urbano'],
          'inviter_name': 'Carla Dias',
          'inviter_avatar_url':
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
        }
      ],
    ),
    MockEventSeed(
      id: 'event-day0-lunch-beats',
      type: _concertType,
      title: 'Lunch Beats',
      content:
          'DJ set groove acompanhando food trucks com pratos autorais para o almoco.',
      location: 'Boulevard Belluga',
      latitude: -20.6685,
      longitude: -40.4954,
      thumbUrl:
          'https://images.unsplash.com/photo-1497032205916-ac775f0649ae?w=800',
      offsetDays: 0,
      startHour: 13,
      durationMinutes: 90,
      artists: const [
        MockArtistSeed(
          id: 'artist-dj-savana',
          name: 'DJ Savana',
          avatarUrl:
              'https://images.unsplash.com/photo-1541532713592-79a0317b6b77?auto=format&fit=crop&w=400&q=80',
          highlight: true,
        ),
      ],
      actionLabel: 'Ouvir set',
      actionUrl: 'https://example.com/lunch-beats',
      actionColor: '#FF4FA0E3',
      sentInvites: [
        {
          'friend': {
            'id': 'friend-3',
            'display_name': 'Lucas Oliveira',
            'avatar_url':
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
          },
          'status': 'accepted',
          'sent_at': '2025-11-20T10:00:00.000',
          'responded_at': '2025-11-20T12:30:00.000',
        },
        {
          'friend': {
            'id': 'friend-4',
            'display_name': 'Mariana Costa',
            'avatar_url':
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
          },
          'status': 'pending',
          'sent_at': '2025-11-21T09:00:00.000',
        },
        {
          'friend': {
            'id': 'friend-5',
            'display_name': 'Rafael Santos',
            'avatar_url':
                'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
          },
          'status': 'declined',
          'sent_at': '2025-11-20T14:00:00.000',
          'responded_at': '2025-11-20T15:00:00.000',
        },
      ],
    ),
    MockEventSeed(
      id: 'event-day0-sunset-acoustic',
      type: _concertType,
      title: 'Sunset Acoustic Session',
      content:
          'Classicos da MPB em versao acustica com o por do sol da Praia da Areia Preta.',
      location: 'Praia da Areia Preta',
      latitude: -20.6649,
      longitude: -40.5011,
      thumbUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=800',
      offsetDays: 0,
      startHour: 17,
      durationMinutes: 110,
      artists: const [
        MockArtistSeed(
          id: 'artist-voz-aurora',
          name: 'Aurora Ribeiro',
          avatarUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Comprar ingresso',
      actionUrl: 'https://example.com/sunset-acoustic',
      actionColor: '#FF4FA0E3',
      totalConfirmed: 45,
      friendsGoing: [
        {
          'id': 'friend-6',
          'display_name': 'Beatriz Lima',
          'avatar_url':
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        },
        {
          'id': 'friend-7',
          'display_name': 'Gabriel Souza',
          'avatar_url':
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
        },
        {
          'id': 'friend-8',
          'display_name': 'Fernanda Alves',
          'avatar_url':
              'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=200',
        },
      ],
    ),
    MockEventSeed(
      id: 'event-day0-electro-sunset',
      type: _concertType,
      title: 'Electro Sunset Party',
      content: 'Line-up de DJs com projecoes visuais e pistas silent-disco.',
      location: 'Orla Central',
      latitude: -20.6678,
      longitude: -40.5029,
      thumbUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
      offsetDays: 0,
      startHour: 20,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-dj-horizonte',
          name: 'DJ Horizonte',
          avatarUrl:
              'https://images.unsplash.com/photo-1541532713592-79a0317b6b77?auto=format&fit=crop&w=400&q=80',
          highlight: true,
        ),
        MockArtistSeed(
          id: 'artist-dj-verde',
          name: 'DJ Verde Mar',
          avatarUrl:
              'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
        ),
      ],
      actionLabel: 'Comprar ingresso',
      actionUrl: 'https://example.com/electro-sunset',
      actionColor: '#FF4FA0E3',
    ),
    // Day 1
    MockEventSeed(
      id: 'event-day1-coastal-run',
      type: _workshopType,
      title: 'Coastal Run Warm-up',
      content:
          'Alongamentos guiados e dicas de respiracao para a corrida costeira.',
      location: 'Pier do Centro',
      latitude: -20.6722,
      longitude: -40.5034,
      thumbUrl:
          'https://images.unsplash.com/photo-1452626038306-9aae5e071dd3?w=800',
      offsetDays: 1,
      startHour: 7,
      durationMinutes: 60,
      artists: const [
        MockArtistSeed(
          id: 'artist-coach-marcio',
          name: 'Coach Marcio Reis',
          avatarUrl:
              'https://images.unsplash.com/photo-1531788612988-9f29f66fcd99?w=200',
        ),
      ],
      actionLabel: 'Inscrever-se',
      actionUrl: 'https://example.com/coastal-run',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day1-coffee-lab',
      type: _workshopType,
      title: 'Coffee Roasting Lab',
      content:
          'Laboratorio sensorial com mestres cafeicultores e torras especiais.',
      location: 'Casa dos Cafes',
      latitude: -20.6754,
      longitude: -40.5001,
      thumbUrl:
          'https://images.unsplash.com/photo-1447933601403-0c6688de566e?w=800',
      offsetDays: 1,
      startHour: 10,
      durationMinutes: 120,
      artists: const [
        MockArtistSeed(
          id: 'artist-barista-joana',
          name: 'Barista Joana Ramos',
          avatarUrl:
              'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?auto=format&fit=crop&w=200&q=80',
          highlight: true,
        ),
      ],
      actionLabel: 'Garantir vaga',
      actionUrl: 'https://example.com/coffee-roasting',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day1-artisan-stage',
      type: _concertType,
      title: 'Artisan Fair Stage',
      content: 'Pocket shows durante a feira de artesaos no centro historico.',
      location: 'Praca Philomeno Pereira',
      latitude: -20.6726,
      longitude: -40.5009,
      thumbUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',
      offsetDays: 1,
      startHour: 14,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-trio-cascata',
          name: 'Trio Cascata',
          avatarUrl:
              'https://images.unsplash.com/photo-1454922915609-78549ad709bb?w=200',
        ),
      ],
      actionLabel: 'Ver programacao',
      actionUrl: 'https://example.com/artisan-stage',
      actionColor: '#FF4FA0E3',
    ),
    MockEventSeed(
      id: 'event-day1-samba-square',
      type: _concertType,
      title: 'Samba na Praca',
      content:
          'Roda de samba com participacoes especiais e repertorio autoral capixaba.',
      location: 'Praca da Matriz',
      latitude: -20.6739,
      longitude: -40.5054,
      thumbUrl:
          'https://images.unsplash.com/photo-1518544889280-0f4e3b8ac60c?w=800',
      offsetDays: 1,
      startHour: 17,
      durationMinutes: 180,
      artists: const [
        MockArtistSeed(
          id: 'artist-samba-coral',
          name: 'Grupo Coral da Barra',
          avatarUrl:
              'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Confirmar presenca',
      actionUrl: 'https://example.com/samba-praca',
      actionColor: '#FF4FA0E3',
    ),
    MockEventSeed(
      id: 'event-day1-starlight-cinema',
      type: _workshopType,
      title: 'Starlight Cinema',
      content:
          'Sessao de cinema ao ar livre com curta-metragens de cineastas locais.',
      location: 'Mirante Alto da Serra',
      latitude: -20.6582,
      longitude: -40.5110,
      thumbUrl:
          'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4?w=800',
      offsetDays: 1,
      startHour: 20,
      durationMinutes: 120,
      artists: const [],
      actionLabel: 'Retirar ingresso',
      actionUrl: 'https://example.com/starlight-cinema',
      actionColor: '#FFE80D5D',
    ),
    // Day 2
    MockEventSeed(
      id: 'event-day2-beach-pilates',
      type: _workshopType,
      title: 'Beach Pilates',
      content:
          'Aula de pilates no areal com foco em fortalecimento e equilibrio.',
      location: 'Praia do Morro Posto 1',
      latitude: -20.6654,
      longitude: -40.4948,
      thumbUrl:
          'https://images.unsplash.com/photo-1452626038306-9aae5e071dd3?w=800',
      offsetDays: 2,
      startHour: 8,
      durationMinutes: 70,
      artists: const [
        MockArtistSeed(
          id: 'artist-ana-oliveira',
          name: 'Ana Oliveira',
          avatarUrl:
              'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=200',
        ),
      ],
      actionLabel: 'Reservar colchonete',
      actionUrl: 'https://example.com/beach-pilates',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day2-ceramic-lab',
      type: _workshopType,
      title: 'Ceramica Contemporanea',
      content:
          'Laboratorio de ceramica com queima raku e tecnicas de texturizacao.',
      location: 'Atelie Terra e Mar',
      latitude: -20.6761,
      longitude: -40.4974,
      thumbUrl:
          'https://images.unsplash.com/photo-1503602642458-232111445657?w=800',
      offsetDays: 2,
      startHour: 10,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-luiza-ceram',
          name: 'Luiza Ceramistas',
          avatarUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
        ),
      ],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/ceramica-contemporanea',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day2-food-trail',
      type: _workshopType,
      title: 'Street Food Trail',
      content:
          'Caminhada guiada degustando petiscos autorais pelos quiosques locais.',
      location: 'Centro Historico',
      latitude: -20.6749,
      longitude: -40.5048,
      thumbUrl:
          'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=800',
      offsetDays: 2,
      startHour: 13,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-chef-paula',
          name: 'Chef Paula Figueiredo',
          avatarUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
        ),
      ],
      actionLabel: 'Garantir lugar',
      actionUrl: 'https://example.com/street-food-tour',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day2-capoeira',
      type: _concertType,
      title: 'Capoeira Sunset Roda',
      content:
          'Apresentacao com grupos tradicionais e oficina aberta ao publico.',
      location: 'Parque da Prainha',
      latitude: -20.6721,
      longitude: -40.4989,
      thumbUrl:
          'https://images.unsplash.com/photo-1545239351-1141bd82e8a6?w=800',
      offsetDays: 2,
      startHour: 16,
      durationMinutes: 120,
      artists: const [
        MockArtistSeed(
          id: 'artist-mestre-marajo',
          name: 'Mestre Marajo',
          avatarUrl:
              'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/capoeira-sunset',
      actionColor: '#FF4FA0E3',
    ),
    MockEventSeed(
      id: 'event-day2-jazz-rooftop',
      type: _concertType,
      title: 'Jazz Rooftop Session',
      content: 'Concerto instrumental com participacao de solistas convidados.',
      location: 'Mirante Alto da Serra',
      latitude: -20.6582,
      longitude: -40.5110,
      thumbUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
      offsetDays: 2,
      startHour: 20,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-quartet-azul',
          name: 'Quarteto Horizonte Azul',
          avatarUrl:
              'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Comprar ingresso',
      actionUrl: 'https://example.com/jazz-under-stars',
      actionColor: '#FF4FA0E3',
    ),
    // Day 3
    MockEventSeed(
      id: 'event-day3-sunrise-meditation',
      type: _workshopType,
      title: 'Sunrise Meditation',
      content:
          'Meditacao guiada com musica ambiente para alinhar corpo e mente.',
      location: 'Parque Morro da Pescaria',
      latitude: -20.6625,
      longitude: -40.4853,
      thumbUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
      offsetDays: 3,
      startHour: 6,
      durationMinutes: 60,
      artists: const [
        MockArtistSeed(
          id: 'artist-thiago-zen',
          name: 'Thiago Zen',
          avatarUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        ),
      ],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/sunrise-meditation',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day3-surf-clinic',
      type: _workshopType,
      title: 'Surf Clinic',
      content:
          'Clinica para surfistas intermediarios com analise de manobras e video.',
      location: 'Praia da Cerca',
      latitude: -20.6468,
      longitude: -40.4862,
      thumbUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      offsetDays: 3,
      startHour: 8,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-instrutor-maresia',
          name: 'Instrutor Maresia',
          avatarUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
        ),
      ],
      actionLabel: 'Reservar prancha',
      actionUrl: 'https://example.com/surf-clinic',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day3-kids-theatre',
      type: _concertType,
      title: 'Teatro Kids',
      content:
          'Peca interativa com fantoches e musica para criancas de 4 a 10 anos.',
      location: 'Centro Cultural Radium',
      latitude: -20.6700,
      longitude: -40.5024,
      thumbUrl:
          'https://images.unsplash.com/photo-1472653816316-3ad6f10a6592?w=800',
      offsetDays: 3,
      startHour: 14,
      durationMinutes: 90,
      artists: const [
        MockArtistSeed(
          id: 'artist-trupe-lua',
          name: 'Trupe Lua Nova',
          avatarUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
        ),
      ],
      actionLabel: 'Garantir ingresso',
      actionUrl: 'https://example.com/teatro-kids',
      actionColor: '#FF4FA0E3',
    ),
    MockEventSeed(
      id: 'event-day3-mixology',
      type: _workshopType,
      title: 'Tropical Mixology Lab',
      content: 'Sessao pratica de coqueteis com ingredientes regionais.',
      location: 'Espaco Mixology Lab',
      latitude: -20.6691,
      longitude: -40.5004,
      thumbUrl:
          'https://images.unsplash.com/photo-1497534446932-c925b458314e?w=800',
      offsetDays: 3,
      startHour: 18,
      durationMinutes: 120,
      artists: const [
        MockArtistSeed(
          id: 'artist-mixologista-lara',
          name: 'Mixologista Lara Silva',
          avatarUrl:
              'https://images.unsplash.com/photo-1521579971123-1192931a1452?w=200',
        ),
      ],
      actionLabel: 'Reservar',
      actionUrl: 'https://example.com/mixology-lab',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day3-rooftop-dj',
      type: _concertType,
      title: 'Rooftop DJ Sessions',
      content:
          'Sets de musica eletronica com projecoes digitais e vista 360 da baia.',
      location: 'Terraco GuarAPPari',
      latitude: -20.6688,
      longitude: -40.4986,
      thumbUrl:
          'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=800',
      offsetDays: 3,
      startHour: 21,
      durationMinutes: 180,
      artists: const [
        MockArtistSeed(
          id: 'artist-dj-lume',
          name: 'DJ Lume',
          avatarUrl:
              'https://images.unsplash.com/photo-1541532713592-79a0317b6b77?auto=format&fit=crop&w=400&q=80',
          highlight: true,
        ),
      ],
      actionLabel: 'Comprar ingresso',
      actionUrl: 'https://example.com/rooftop-dj',
      actionColor: '#FF4FA0E3',
    ),
    // Day 4
    MockEventSeed(
      id: 'event-day4-trail-hike',
      type: _workshopType,
      title: 'Trail Hike Guarapari',
      content:
          'Trilha guiada com interpretacao ambiental pelo Parque da Pescaria.',
      location: 'Entrada Parque Pescaria',
      latitude: -20.6610,
      longitude: -40.4860,
      thumbUrl:
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',
      offsetDays: 4,
      startHour: 7,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-guia-ana',
          name: 'Guia Ana Prado',
          avatarUrl:
              'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=200',
        ),
      ],
      actionLabel: 'Reservar vaga',
      actionUrl: 'https://example.com/trail-hike',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day4-photo-walk',
      type: _workshopType,
      title: 'Photo Walk Centro Historico',
      content:
          'Roteiro fotografico com dicas de composicao e luz nas construcoes coloniais.',
      location: 'Praca Manoel Teixeira',
      latitude: -20.6734,
      longitude: -40.5035,
      thumbUrl:
          'https://images.unsplash.com/photo-1473862170182-43c138187c39?w=800',
      offsetDays: 4,
      startHour: 9,
      durationMinutes: 120,
      artists: const [
        MockArtistSeed(
          id: 'artist-foto-helena',
          name: 'Fotografa Helena Luz',
          avatarUrl:
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/photo-walk',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day4-farmers-brunch',
      type: _workshopType,
      title: 'Farmers Brunch',
      content:
          'Banquete colaborativo com produtos organicos e apresentacoes de pequenos produtores.',
      location: 'Quintal Agroecologico',
      latitude: -20.6767,
      longitude: -40.4981,
      thumbUrl:
          'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=800',
      offsetDays: 4,
      startHour: 12,
      durationMinutes: 180,
      artists: const [],
      actionLabel: 'Confirmar presenca',
      actionUrl: 'https://example.com/farmers-brunch',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day4-chorinho',
      type: _concertType,
      title: 'Chorinho na Rua',
      content:
          'Roda de chorinho com repertorio tradicional e intervencoes de danca.',
      location: 'Rua Joaquim Fonseca',
      latitude: -20.6718,
      longitude: -40.5007,
      thumbUrl:
          'https://images.unsplash.com/photo-1518544889280-0f4e3b8ac60c?w=800',
      offsetDays: 4,
      startHour: 17,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-choro-encanto',
          name: 'Grupo Choro Encanto',
          avatarUrl:
              'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=200',
        ),
      ],
      actionLabel: 'Contribuir com o chapeu',
      actionUrl: 'https://example.com/chorinho-rua',
      actionColor: '#FF4FA0E3',
    ),
    MockEventSeed(
      id: 'event-day4-poetry',
      type: _concertType,
      title: 'Moonlight Poetry Slam',
      content:
          'Batalha de poesia com musicistas convidadas e microfone aberto.',
      location: 'Anfiteatro Praia dos Namorados',
      latitude: -20.6660,
      longitude: -40.4996,
      thumbUrl:
          'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=800',
      offsetDays: 4,
      startHour: 20,
      durationMinutes: 120,
      artists: const [
        MockArtistSeed(
          id: 'artist-poeta-lotus',
          name: 'Poeta Lotus',
          avatarUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Inscrever poema',
      actionUrl: 'https://example.com/moonlight-poetry',
      actionColor: '#FF4FA0E3',
    ),
    // Day 5
    MockEventSeed(
      id: 'event-day5-sup-session',
      type: _workshopType,
      title: 'SUP Session',
      content:
          'Aula de stand up paddle com foco em equilibrio e navegacao costeira.',
      location: 'Enseada Azul',
      latitude: -20.6508,
      longitude: -40.4912,
      thumbUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=800',
      offsetDays: 5,
      startHour: 8,
      durationMinutes: 90,
      artists: const [
        MockArtistSeed(
          id: 'artist-instrutor-caique',
          name: 'Instrutor Caique Ramos',
          avatarUrl:
              'https://images.unsplash.com/photo-1521579971123-1192931a1452?w=200',
        ),
      ],
      actionLabel: 'Reservar prancha',
      actionUrl: 'https://example.com/sup-session',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day5-ceramic-studio',
      type: _workshopType,
      title: 'Studio de Ceramica',
      content:
          'Workshop avancado de torno e esmaltacao guiado por artistas residentes.',
      location: 'Atelie Terra e Mar',
      latitude: -20.6761,
      longitude: -40.4974,
      thumbUrl:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800',
      offsetDays: 5,
      startHour: 10,
      durationMinutes: 180,
      artists: const [
        MockArtistSeed(
          id: 'artist-luiza-ceram',
          name: 'Luiza Ceramistas',
          avatarUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
        ),
      ],
      actionLabel: 'Garantir vaga',
      actionUrl: 'https://example.com/studio-ceramica',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day5-vegan-popup',
      type: _workshopType,
      title: 'Vegan Pop-up Lunch',
      content:
          'Menu degustacao com chefs convidados explorando ingredientes locais.',
      location: 'Praca Gastronomica',
      latitude: -20.6733,
      longitude: -40.5018,
      thumbUrl:
          'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=800',
      offsetDays: 5,
      startHour: 13,
      durationMinutes: 120,
      artists: const [
        MockArtistSeed(
          id: 'artist-chef-luana',
          name: 'Chef Luana Celeste',
          avatarUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Reservar mesa',
      actionUrl: 'https://example.com/vegan-popup',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day5-forro-night',
      type: _concertType,
      title: 'Forro na Orla',
      content:
          'Aula coletiva seguida de show com trio pe de serra e dancarinos convidados.',
      location: 'Orla Central',
      latitude: -20.6678,
      longitude: -40.5029,
      thumbUrl:
          'https://images.unsplash.com/photo-1518544889280-0f4e3b8ac60c?w=800',
      offsetDays: 5,
      startHour: 18,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-trio-sereno',
          name: 'Trio Sereno',
          avatarUrl:
              'https://images.unsplash.com/photo-1454922915609-78549ad709bb?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Comprar ingresso',
      actionUrl: 'https://example.com/forro-orla',
      actionColor: '#FF4FA0E3',
    ),
    MockEventSeed(
      id: 'event-day5-astronomy-talk',
      type: _workshopType,
      title: 'Astronomy Talk',
      content:
          'Observacao do ceu com telescopios e bate-papo com astronomos convidados.',
      location: 'Mirante Alto da Serra',
      latitude: -20.6582,
      longitude: -40.5110,
      thumbUrl:
          'https://images.unsplash.com/photo-1496307042754-b4aa456c4a2d?w=800',
      offsetDays: 5,
      startHour: 21,
      durationMinutes: 120,
      artists: const [],
      actionLabel: 'Inscrever-se',
      actionUrl: 'https://example.com/astronomy-talk',
      actionColor: '#FFE80D5D',
    ),
    // Day 6
    MockEventSeed(
      id: 'event-day6-trail-run',
      type: _workshopType,
      title: 'Trail Run Experience',
      content:
          'Treino guiado por trilhas com foco em tecnicas de subida e descida.',
      location: 'Trilha do Ermitao',
      latitude: -20.6620,
      longitude: -40.4872,
      thumbUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=80',
      offsetDays: 6,
      startHour: 7,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-coach-bruno',
          name: 'Coach Bruno Sal',
          avatarUrl:
              'https://images.unsplash.com/photo-1531788612988-9f29f66fcd99?w=200',
        ),
      ],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/trail-run',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day6-mindfulness',
      type: _workshopType,
      title: 'Mindfulness Lab',
      content:
          'Sessao de mindfulness com instrumentos ancestrais e aromaterapia.',
      location: 'Casa GuarAPPari',
      latitude: -20.6750,
      longitude: -40.5000,
      thumbUrl:
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800',
      offsetDays: 6,
      startHour: 10,
      durationMinutes: 120,
      artists: const [
        MockArtistSeed(
          id: 'artist-samira-luz',
          name: 'Samira Luz',
          avatarUrl:
              'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?auto=format&fit=crop&w=200&q=80',
        ),
      ],
      actionLabel: 'Garantir presenca',
      actionUrl: 'https://example.com/mindfulness-lab',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day6-beer-tour',
      type: _workshopType,
      title: 'Craft Beer Tour',
      content:
          'Tour guiado por microcervejarias com degustacao harmonizada e musica ao vivo.',
      location: 'Circuito Cervejeiro',
      latitude: -20.6768,
      longitude: -40.4989,
      thumbUrl:
          'https://images.unsplash.com/photo-1501183638710-841dd1904471?w=800',
      offsetDays: 6,
      startHour: 14,
      durationMinutes: 180,
      artists: const [],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/craft-beer-tour',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day6-percussion',
      type: _concertType,
      title: 'Percussion Circle',
      content:
          'Vivencia percussiva coletiva com mestres de maracatu e congado.',
      location: 'Praca do Sol',
      latitude: -20.6704,
      longitude: -40.4992,
      thumbUrl:
          'https://images.unsplash.com/photo-1518544889280-0f4e3b8ac60c?w=800',
      offsetDays: 6,
      startHour: 18,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-mestra-fogo',
          name: 'Mestra Fogo',
          avatarUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/percussion-circle',
      actionColor: '#FF4FA0E3',
    ),
    MockEventSeed(
      id: 'event-day6-night-market',
      type: _concertType,
      title: 'Night Market Beats',
      content:
          'Programacao musical acompanhando a feira noturna de empreendedores.',
      location: 'Boulevard Belluga',
      latitude: -20.6685,
      longitude: -40.4954,
      thumbUrl:
          'https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?w=800',
      offsetDays: 6,
      startHour: 21,
      durationMinutes: 180,
      artists: const [
        MockArtistSeed(
          id: 'artist-dj-riera',
          name: 'DJ Riera',
          avatarUrl:
              'https://images.unsplash.com/photo-1541532713592-79a0317b6b77?auto=format&fit=crop&w=400&q=80',
        ),
      ],
      actionLabel: 'Ver agenda',
      actionUrl: 'https://example.com/night-market-beats',
      actionColor: '#FF4FA0E3',
    ),
    // Day 7
    MockEventSeed(
      id: 'event-day7-cleanup',
      type: _workshopType,
      title: 'Coastal Cleanup',
      content:
          'Mutirao colaborativo de limpeza com briefing ambiental e triagem de residuos.',
      location: 'Praia do Morro Posto 4',
      latitude: -20.6668,
      longitude: -40.4994,
      thumbUrl:
          'https://images.unsplash.com/photo-1529612700005-e35377bf1415?w=800',
      offsetDays: 7,
      startHour: 7,
      durationMinutes: 120,
      artists: const [],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/coastal-cleanup',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day7-sea-turtle-talk',
      type: _workshopType,
      title: 'Sea Turtle Talk',
      content:
          'Palestra sobre conservacao marinha com pesquisadores e visita guiada.',
      location: 'Centro Ambiental Guarapari',
      latitude: -20.6715,
      longitude: -40.4975,
      thumbUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=80',
      offsetDays: 7,
      startHour: 9,
      durationMinutes: 90,
      artists: const [
        MockArtistSeed(
          id: 'artist-bio-camila',
          name: 'Biologa Camila Nery',
          avatarUrl:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        ),
      ],
      actionLabel: 'Confirmar presenca',
      actionUrl: 'https://example.com/sea-turtle-talk',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day7-food-fest',
      type: _workshopType,
      title: 'Local Food Fest',
      content:
          'Festival gastronomico com chefs convidados, oficinas e area kids.',
      location: 'Parque da Prainha',
      latitude: -20.6721,
      longitude: -40.4989,
      thumbUrl:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800',
      offsetDays: 7,
      startHour: 12,
      durationMinutes: 240,
      artists: const [
        MockArtistSeed(
          id: 'artist-chef-matheus',
          name: 'Chef Matheus Prado',
          avatarUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
        ),
      ],
      actionLabel: 'Comprar ingresso',
      actionUrl: 'https://example.com/local-food-fest',
      actionColor: '#FFE80D5D',
    ),
    MockEventSeed(
      id: 'event-day7-sunset-cinema',
      type: _concertType,
      title: 'Sunset Cinema e Jazz',
      content:
          'Exibicao de filme com encerramento musical ao vivo no gramado do parque.',
      location: 'Parque Morro da Pescaria',
      latitude: -20.6625,
      longitude: -40.4853,
      thumbUrl:
          'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4?w=800',
      offsetDays: 7,
      startHour: 17,
      durationMinutes: 150,
      artists: const [
        MockArtistSeed(
          id: 'artist-jazz-trio-mar',
          name: 'Trio Mar Azul',
          avatarUrl:
              'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=200',
        ),
      ],
      actionLabel: 'Retirar ingresso',
      actionUrl: 'https://example.com/sunset-cinema',
      actionColor: '#FF4FA0E3',
    ),
    MockEventSeed(
      id: 'event-day7-lantern-walk',
      type: _concertType,
      title: 'Midnight Lantern Walk',
      content:
          'Caminhada noturna com lanternas artesanais e trilha sonora ao vivo.',
      location: 'Praca da Paz',
      latitude: -20.6690,
      longitude: -40.5030,
      thumbUrl:
          'https://images.unsplash.com/photo-1473862170182-43c138187c39?w=800',
      offsetDays: 7,
      startHour: 22,
      durationMinutes: 120,
      artists: const [
        MockArtistSeed(
          id: 'artist-coletivo-lumen',
          name: 'Coletivo Lumen',
          avatarUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/lantern-walk',
      actionColor: '#FF4FA0E3',
    ),
  ];
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
      receivedInvites: receivedInvites,
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
      location: venue.name,
      latitude: venue.latitude,
      longitude: venue.longitude,
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
