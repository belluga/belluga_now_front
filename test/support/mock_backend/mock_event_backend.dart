import 'package:belluga_now/infrastructure/dal/dao/event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/event/event_preview_dto.dart';

class MockEventBackend extends EventBackendContract {
  static final List<EventPreviewDTO> _featuredEvents = [
    EventPreviewDTO(
      id: 'event-day0-morning-flow',
      title: 'Festival de Verao',
      imageUrl:
          'https://images.unsplash.com/photo-1524368535928-5b5e00ddc76b?w=800',
      startDateTime: DateTime(2024, 1, 7, 20, 0),
      location: 'Praia do Morro',
      artist: 'DJ Mare Alta',
    ),
    EventPreviewDTO(
      id: 'event-day0-sunset-acoustic',
      title: 'Luau Exclusivo',
      imageUrl:
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
      startDateTime: DateTime(2024, 1, 8, 22, 0),
      location: 'Areia Preta',
      artist: 'Banda Eclipse',
    ),
    EventPreviewDTO(
      id: 'event-day0-electro-sunset',
      title: 'Sunset Experience',
      imageUrl:
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800',
      startDateTime: DateTime(2024, 1, 9, 18, 0),
      location: 'Parque da Areia',
      artist: 'DJ Horizonte',
    ),
  ];

  static final List<EventPreviewDTO> _upcomingEvents = [
    EventPreviewDTO(
      id: 'event-day1-coffee-lab',
      title: 'Circuito Gastronomico',
      imageUrl:
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      startDateTime: DateTime(2024, 1, 12, 19, 30),
      location: 'Bistro da Orla',
      artist: 'Chef Paula Figueiredo',
    ),
    EventPreviewDTO(
      id: 'event-day1-coastal-run',
      title: 'Passeio de Escuna',
      imageUrl:
          'https://images.unsplash.com/photo-1493558103817-58b2924bce98?w=800',
      startDateTime: DateTime(2024, 1, 13, 9, 0),
      location: 'Porto da Barra',
      artist: 'Guia Clara Nunes',
    ),
    EventPreviewDTO(
      id: 'event-day1-artisan-stage',
      title: 'Tour Historico a Pe',
      imageUrl:
          'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=800',
      startDateTime: DateTime(2024, 1, 14, 15, 0),
      location: 'Centro Historico',
      artist: 'Historiador Joao Mendes',
    ),
  ];

  @override
  Future<List<EventPreviewDTO>> fetchFeaturedEvents() async {
    return List<EventPreviewDTO>.unmodifiable(_featuredEvents);
  }

  @override
  Future<List<EventPreviewDTO>> fetchUpcomingEvents() async {
    return List<EventPreviewDTO>.unmodifiable(_upcomingEvents);
  }
}
