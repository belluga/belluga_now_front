import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_actions_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_summary_item_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/thumb_dto.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';

class MockScheduleBackend implements ScheduleBackendContract {
  MockScheduleBackend();

  @override
  Future<EventSummaryDTO> fetchSummary() async {
    final events = await fetchEvents();
    final items = events
        .map(
          (event) => EventSummaryItemDTO(
            dateTimeStart: event.dateTimeStart,
            color: event.type.color,
          ),
        )
        .toList();

    return EventSummaryDTO(items: items);
  }

  @override
  Future<List<EventDTO>> fetchEvents() async {
    final events = _eventSeeds.map((seed) => seed.toDto(_today)).toList()
      ..sort((a, b) => DateTime.parse(a.dateTimeStart)
          .compareTo(DateTime.parse(b.dateTimeStart)));

    return events;
  }

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static final _concertType = EventTypeDTO(
    id: 'concert',
    name: 'Show',
    slug: 'show',
    description: 'Apresentacoes ao vivo',
    icon: 'music',
    color: '#FF4FA0E3',
  );

  static final _workshopType = EventTypeDTO(
    id: 'workshop',
    name: 'Oficina',
    slug: 'oficina',
    description: 'Atividades guiadas com especialistas',
    icon: 'workshop',
    color: '#FFE80D5D',
  );

  static final List<_MockEventSeed> _eventSeeds = [
    _MockEventSeed(
      id: 'event-yesterday-acoustic',
      type: _concertType,
      title: 'Acoustic Evening at the Garden',
      content:
          'Encontro intimista com classicos reinterpretados em formato acustico.',
      location: 'Garden Stage Centro',
      latitude: -20.6714,
      longitude: -40.5042,
      thumbUrl:
          'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?w=800',
      offsetDays: -1,
      startHour: 20,
      artists: const [
        _MockArtistSeed(
          id: 'artist-acoustic',
          name: 'Duo Horizonte',
          avatarUrl:
              'https://images.unsplash.com/photo-1549068146-79fa64ac84c2?w=200',
        ),
      ],
      actionLabel: 'Assistir reprise',
      actionUrl: 'https://example.com/acoustic-evening',
      actionColor: '#FF4FA0E3',
    ),
    _MockEventSeed(
      id: 'event-today-yoga',
      type: _workshopType,
      title: 'Sunrise Yoga Flow',
      content:
          'Sessao matinal ao ar livre focada em respiracao e alongamentos.',
      location: 'Deck Praia do Morro',
      latitude: -20.6634,
      longitude: -40.4976,
      thumbUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
      offsetDays: 0,
      startHour: 9,
      artists: const [
        _MockArtistSeed(
          id: 'artist-yoga',
          name: 'Instrutora Marina Luz',
          avatarUrl:
              'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?w=200',
          highlight: true,
        ),
      ],
      actionLabel: 'Reservar vaga',
      actionUrl: 'https://example.com/sunrise-yoga',
      actionColor: '#FFE80D5D',
    ),
    _MockEventSeed(
      id: 'event-today-party',
      type: _concertType,
      title: 'Electro Sunset Party',
      content: 'Line-up de DJs com sets ao vivo e visual do por do sol.',
      location: 'Orla Central',
      latitude: -20.6678,
      longitude: -40.5029,
      thumbUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
      offsetDays: 0,
      startHour: 19,
      artists: const [
        _MockArtistSeed(
          id: 'artist-dj-horizonte',
          name: 'DJ Horizonte',
          avatarUrl:
              'https://images.unsplash.com/photo-1549213820-0fedc82f3817?w=200',
          highlight: true,
        ),
        _MockArtistSeed(
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
    _MockEventSeed(
      id: 'event-tomorrow-food',
      type: _workshopType,
      title: 'Street Food Tour',
      content:
          'Caminhada guiada degustando petiscos autorais pelos quiosques locais.',
      location: 'Centro Historico',
      latitude: -20.6749,
      longitude: -40.5048,
      thumbUrl:
          'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=800',
      offsetDays: 1,
      startHour: 12,
      artists: const [
        _MockArtistSeed(
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
    _MockEventSeed(
      id: 'event-two-days-mixology',
      type: _workshopType,
      title: 'Tropical Mixology Lab',
      content: 'Sessao pratica de coqueteis com ingredientes regionais.',
      location: 'Espaco Mixology Lab',
      latitude: -20.6691,
      longitude: -40.5004,
      thumbUrl:
          'https://images.unsplash.com/photo-1497534446932-c925b458314e?w=800',
      offsetDays: 2,
      startHour: 18,
      artists: const [
        _MockArtistSeed(
          id: 'artist-mixology',
          name: 'Mixologista Lara Silva',
          avatarUrl:
              'https://images.unsplash.com/photo-1521579971123-1192931a1452?w=200',
        ),
      ],
      actionLabel: 'Reservar',
      actionUrl: 'https://example.com/mixology-lab',
      actionColor: '#FFE80D5D',
    ),
    _MockEventSeed(
      id: 'event-two-days-jazz',
      type: _concertType,
      title: 'Jazz Under the Stars',
      content: 'Concerto instrumental com participacao de solistas convidados.',
      location: 'Mirante Alto da Serra',
      latitude: -20.6582,
      longitude: -40.511,
      thumbUrl:
          'https://images.unsplash.com/photo-1526925539332-aa3b66e35444?w=800',
      offsetDays: 2,
      startHour: 21,
      artists: const [
        _MockArtistSeed(
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
    _MockEventSeed(
      id: 'event-three-days-sketch',
      type: _workshopType,
      title: 'Urban Sketching Walk',
      content:
          'Workshop itinerante registrando cenas urbanas com tecnicas rapidas.',
      location: 'Praca Central',
      latitude: -20.6743,
      longitude: -40.4978,
      thumbUrl:
          'https://images.unsplash.com/photo-1473862170182-43c138187c39?w=800',
      offsetDays: 3,
      startHour: 10,
      artists: const [
        _MockArtistSeed(
          id: 'artist-arte-leo',
          name: 'Artista Leo Ramos',
          avatarUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
        ),
      ],
      actionLabel: 'Participar',
      actionUrl: 'https://example.com/urban-sketch',
      actionColor: '#FFE80D5D',
    ),
    _MockEventSeed(
      id: 'event-five-days-market',
      type: _concertType,
      title: 'Night Market Beats',
      content:
          'Programacao musical acompanhando a feira noturna de empreendedores.',
      location: 'Boulevard Belluga',
      latitude: -20.6685,
      longitude: -40.4954,
      thumbUrl:
          'https://images.unsplash.com/photo-1497032628192-86f99bcd76bc?w=800',
      offsetDays: 5,
      startHour: 17,
      artists: const [],
      actionLabel: 'Ver agenda',
      actionUrl: 'https://example.com/night-market-beats',
      actionColor: '#FF4FA0E3',
    ),
  ];
}

class _MockEventSeed {
  const _MockEventSeed({
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
    this.startMinute = 0,
    required this.artists,
    required this.actionLabel,
    required this.actionUrl,
    required this.actionColor,
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
  final int startMinute;
  final List<_MockArtistSeed> artists;
  final String actionLabel;
  final String actionUrl;
  final String actionColor;

  EventDTO toDto(DateTime baseDate) {
    final date = baseDate.add(
      Duration(
        days: offsetDays,
        hours: startHour,
        minutes: startMinute,
      ),
    );

    return EventDTO(
      id: id,
      type: type,
      title: title,
      content: content,
      location: location,
      latitude: latitude,
      longitude: longitude,
      thumb: ThumbDTO(
        type: 'image',
        data: {'url': thumbUrl},
      ),
      dateTimeStart: date.toIso8601String(),
      artists: artists.map((artist) => artist.toDto()).toList(),
      actions: [
        EventActionsDTO(
          label: actionLabel,
          openIn: 'external',
          externalUrl: actionUrl,
          color: actionColor,
        ),
      ],
    );
  }
}

class _MockArtistSeed {
  const _MockArtistSeed({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.highlight = false,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final bool highlight;

  EventArtistDTO toDto() {
    return EventArtistDTO(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      highlight: highlight,
    );
  }
}
