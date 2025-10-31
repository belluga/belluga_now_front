class EventArtistDTO {
  const EventArtistDTO({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.highlight,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final bool? highlight;
}
