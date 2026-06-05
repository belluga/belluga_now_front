typedef EventInviteShareParticipantGroup = ({
  String label,
  List<String> names,
});

final class EventInviteSharePayloadBuilder {
  EventInviteSharePayloadBuilder._();

  static ({String subject, String message}) buildInvitation({
    required String eventName,
    required String location,
    required String eventScheduleLabel,
    required Uri inviteUri,
    String? inviterName,
    List<EventInviteShareParticipantGroup> participantGroups = const [],
  }) {
    final title = eventName.trim();
    final safeTitle = title.isEmpty ? 'esse evento' : title;
    final place = location.trim();
    final schedule = eventScheduleLabel.trim();
    final inviter = inviterName?.trim();
    final lines = <String>[
      if (inviter != null && inviter.isNotEmpty)
        '$inviter te convidou para $safeTitle.'
      else
        'Convite para $safeTitle.',
    ];

    final contextLines = <String>[
      if (schedule.isNotEmpty) schedule,
      if (place.isNotEmpty) place,
    ];
    if (contextLines.isNotEmpty) {
      lines
        ..add('')
        ..addAll(contextLines);
    }

    final participantLines = _participantLines(participantGroups);
    if (participantLines.isNotEmpty) {
      lines
        ..add('')
        ..add('Participantes:')
        ..addAll(participantLines);
    }

    lines
      ..add('')
      ..add('Responder ao convite:')
      ..add(inviteUri.toString());

    return (
      subject: 'Convite para $safeTitle',
      message: lines.join('\n'),
    );
  }

  static ({String subject, String message}) buildPublicShare({
    required String eventName,
    required String location,
    required String eventScheduleLabel,
    required Uri publicUri,
    List<EventInviteShareParticipantGroup> participantGroups = const [],
  }) {
    final title = eventName.trim();
    final safeTitle = title.isEmpty ? 'Evento' : title;
    final place = location.trim();
    final schedule = eventScheduleLabel.trim();
    final lines = <String>[safeTitle];

    final contextLines = <String>[
      if (schedule.isNotEmpty) schedule,
      if (place.isNotEmpty) place,
    ];
    if (contextLines.isNotEmpty) {
      lines
        ..add('')
        ..addAll(contextLines);
    }

    final participantLines = _participantLines(participantGroups);
    if (participantLines.isNotEmpty) {
      lines
        ..add('')
        ..add('Participantes:')
        ..addAll(participantLines);
    }

    lines
      ..add('')
      ..add('Ver evento:')
      ..add(publicUri.toString());

    return (
      subject: safeTitle,
      message: lines.join('\n'),
    );
  }

  static String preview({
    required String eventName,
    required String location,
    required String eventScheduleLabel,
    String? inviterName,
  }) {
    final title = eventName.trim();
    final safeTitle = title.isEmpty ? 'esse evento' : title;
    final place = location.trim();
    final placeClause = place.isEmpty ? '' : ' em $place';
    final schedule = eventScheduleLabel.trim();
    final inviter = inviterName?.trim();
    final intro = inviter != null && inviter.isNotEmpty
        ? '$inviter te convidou para $safeTitle.'
        : 'Convite para $safeTitle.';

    final details = '$schedule$placeClause'.trim();
    if (details.isEmpty) {
      return intro;
    }
    return '$intro $details.';
  }

  static List<String> _participantLines(
    List<EventInviteShareParticipantGroup> groups,
  ) {
    final lines = <String>[];
    for (final group in groups) {
      final label = group.label.trim();
      final names = _dedupeNames(group.names);
      if (names.isEmpty) {
        continue;
      }
      final visibleNames = names.take(2).join(', ');
      final remainingCount = names.length - 2;
      final compactNames = remainingCount > 0
          ? '$visibleNames, e mais $remainingCount'
          : visibleNames;
      lines.add(label.isEmpty ? compactNames : '$label: $compactNames');
    }
    return lines;
  }

  static List<String> _dedupeNames(List<String> names) {
    final seen = <String>{};
    final deduped = <String>[];
    for (final name in names) {
      final normalized = name.trim();
      if (normalized.isEmpty || !seen.add(normalized.toLowerCase())) {
        continue;
      }
      deduped.add(normalized);
    }
    return deduped;
  }
}
