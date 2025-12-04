import 'package:belluga_now/domain/schedule/event_action_types.dart';

class EventActionDTO {
  const EventActionDTO({
    this.id,
    required this.label,
    required this.openIn,
    this.color,
    this.itemType,
    this.itemId,
    this.externalUrl,
    this.message,
  });

  final String? id;
  final String label;
  final String openIn;
  final String? color;
  final String? itemType;
  final String? itemId;
  final String? externalUrl;
  final String? message;

  factory EventActionDTO.fromJson(Map<String, dynamic> json) {
    return EventActionDTO(
      id: json['id'] as String?,
      label: json['label'] as String? ?? '',
      openIn: json['open_in'] as String? ??
          json['type'] as String? ??
          EventActionTypes.external.name,
      color: json['color'] as String?,
      itemType: json['item_type'] as String?,
      itemId: json['item_id'] as String?,
      externalUrl: json['external_url'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'open_in': openIn,
      'color': color,
      'item_type': itemType,
      'item_id': itemId,
      'external_url': externalUrl,
      'message': message,
    };
  }
}
