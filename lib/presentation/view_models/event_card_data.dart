class EventCardData {
  const EventCardData({
    required this.slug,
    required this.title,
    required this.imageUrl,
    required this.startDateTime,
    required this.venue,
    required this.participants,
  });

  final String slug;
  final String title;
  final String imageUrl;
  final DateTime startDateTime;
  final String venue;
  final List<EventParticipantData> participants;

  bool get hasParticipants => participants.isNotEmpty;

  String get participantsLabel =>
      hasParticipants ? participants.map((p) => p.name).join(', ') : '';

  String get participantsLabelWithHighlight {
    if (!hasParticipants) {
      return '';
    }

    return participants
        .map(
          (p) => p.isHighlight ? '${p.name} ★' : p.name,
        )
        .join(', ');
  }
}

class EventParticipantData {
  const EventParticipantData({
    required this.name,
    this.isHighlight = false,
  });

  final String name;
  final bool isHighlight;
}
