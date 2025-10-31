class EventTypeDTO {
  const EventTypeDTO({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String? icon;
  final String? color;
}
