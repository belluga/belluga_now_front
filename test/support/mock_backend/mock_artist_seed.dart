import 'package:belluga_now/infrastructure/dal/dto/schedule/event_artist_dto.dart';

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
