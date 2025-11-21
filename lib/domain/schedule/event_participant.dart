import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

/// Links a Partner to an event with a specific role
/// Allows the same Partner to have different roles in different events
/// (e.g., a musician in one event, an artisan in another)
class EventParticipant {
  final PartnerResume partner;
  final TitleValue role; // e.g., "Músico", "Artesão", "Food Truck"
  final bool isHighlight; // Featured participant
  
  EventParticipant({
    required this.partner,
    required this.role,
    this.isHighlight = false,
  });
  
  factory EventParticipant.fromDto(Map<String, dynamic> dto) {
    return EventParticipant(
      partner: PartnerResume.fromDto(dto['partner']),
      role: TitleValue()..parse(dto['role'] ?? ''),
      isHighlight: dto['is_highlight'] ?? false,
    );
  }
}
