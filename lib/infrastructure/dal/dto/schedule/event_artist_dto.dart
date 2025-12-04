class EventArtistDTO {
  const EventArtistDTO({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.highlight,
    this.genres = const [],
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final bool? highlight;
  final List<String> genres;
}
