class EventActionDto {
  final String? id;
  final String label;
  final String type;
  final String? externalUrl;
  final String? color;
  final String? message;

  EventActionDto({
    this.id,
    required this.label,
    required this.type,
    this.externalUrl,
    this.color,
    this.message,
  });

  factory EventActionDto.fromJson(Map<String, dynamic> json) {
    return EventActionDto(
      id: json['id'] as String?,
      label: json['label'] as String,
      type: json['type'] as String,
      externalUrl: json['external_url'] as String?,
      color: json['color'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type,
      'external_url': externalUrl,
      'color': color,
      'message': message,
    };
  }
}
