import 'package:belluga_now/infrastructure/services/dal/dto/course/teacher_dto.dart';
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
    return _events;
  }

  static final _concertType = EventTypeDTO(
    id: 'concert',
    name: 'Show',
    slug: 'show',
    description: 'Apresentacoes ao vivo',
    icon: 'music',
    color: '#FFE80D5D',
  );

  static final _workshopType = EventTypeDTO(
    id: 'workshop',
    name: 'Oficina',
    slug: 'oficina',
    description: 'Atividades guiadas com especialistas',
    icon: 'workshop',
    color: '#FF4FA0E3',
  );

  static final List<EventDTO> _events = [
    EventDTO(
      id: 'event-1',
      type: _concertType,
      title: 'Sunset Experience',
      content:
          'Uma experiencia musical inesquecivel com artistas locais e DJs convidados.',
      thumb: ThumbDTO(
        type: 'image',
        data: {
          'url':
              'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800',
        },
      ),
      dateTimeStart:
          DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      teachers: [
        TeacherDTO(
          id: 'teacher-a',
          name: 'DJ Horizonte',
          avatarUrl:
              'https://images.unsplash.com/photo-1549213820-0fedc82f3817?w=200',
          highlight: true,
        ),
      ],
      actions: const [
        EventActionsDTO(
          label: 'Comprar ingresso',
          openIn: 'external',
          externalUrl: 'https://example.com/sunset-experience',
          color: '#FF4FA0E3',
        ),
      ],
    ),
    EventDTO(
      id: 'event-2',
      type: _workshopType,
      title: 'Gastronomia Regional com Chef Paula',
      content: 'Aprenda receitas exclusivas inspiradas na culinaria capixaba.',
      thumb: ThumbDTO(
        type: 'image',
        data: {
          'url':
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
        },
      ),
      dateTimeStart:
          DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      teachers: [
        TeacherDTO(
          id: 'teacher-b',
          name: 'Chef Paula Figueiredo',
          avatarUrl:
              'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=200',
          highlight: false,
        ),
      ],
      actions: const [
        EventActionsDTO(
          label: 'Detalhes',
          openIn: 'external',
          externalUrl: 'https://example.com/oficina-gastronomia',
          color: '#FFE80D5D',
        ),
      ],
    ),
    EventDTO(
      id: 'event-3',
      type: _concertType,
      title: 'Noite da Bossa Nova',
      content: 'Espaco intimista com interpretacoes de clasicos da Bossa Nova.',
      thumb: ThumbDTO(
        type: 'image',
        data: {
          'url':
              'https://images.unsplash.com/photo-1527866959252-deab85ef7d1b?w=800',
        },
      ),
      dateTimeStart:
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      teachers: [
        TeacherDTO(
          id: 'teacher-c',
          name: 'Quarteto Mar Azul',
          avatarUrl:
              'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200',
          highlight: false,
        ),
      ],
      actions: const [
        EventActionsDTO(
          label: 'Assistir Gravacao',
          openIn: 'external',
          externalUrl: 'https://example.com/bossa-nova',
          color: '#FF4FA0E3',
        ),
      ],
    ),
  ];
}
