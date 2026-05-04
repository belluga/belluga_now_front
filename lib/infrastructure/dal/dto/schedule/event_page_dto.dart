import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:flutter/foundation.dart';

class EventPageDTO {
  EventPageDTO({
    required this.events,
    required this.hasMore,
  });

  final List<EventDTO> events;
  final bool hasMore;

  factory EventPageDTO.fromJson(Map<String, dynamic> json) {
    final items = _parseItems(json['items']);
    return EventPageDTO(
      events: items,
      hasMore: _asBool(json['has_more']),
    );
  }

  List<EventModel> toDomainEvents() {
    final mapped = <EventModel>[];

    for (final event in events) {
      try {
        mapped.add(event.toDomain());
      } catch (error) {
        final context = _describeEvent(event);
        debugPrint(
          'Skipping malformed agenda event during domain mapping'
          '${context.isEmpty ? '' : ' [$context]'}: $error',
        );
      }
    }

    return List<EventModel>.unmodifiable(mapped);
  }

  static List<EventDTO> _parseItems(Object? rawItems) {
    if (rawItems is! List) {
      return const <EventDTO>[];
    }

    final items = <EventDTO>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        continue;
      }

      String eventContext = '';
      try {
        final item = Map<String, dynamic>.from(rawItem);
        eventContext = _describeItem(item);
        items.add(EventDTO.fromJson(item));
      } catch (error) {
        debugPrint(
          'Skipping malformed agenda event payload'
          '${eventContext.isEmpty ? '' : ' [$eventContext]'}: $error',
        );
      }
    }

    return List<EventDTO>.unmodifiable(items);
  }

  static bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    switch (value?.toString().trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
        return true;
      case '0':
      case 'false':
      case 'no':
        return false;
      default:
        return false;
    }
  }

  static String _describeItem(Map<String, dynamic> item) {
    final parts = <String>[];

    void addPart(String key) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isEmpty) {
        return;
      }
      parts.add('$key=$value');
    }

    addPart('event_id');
    addPart('occurrence_id');
    addPart('slug');

    return parts.join(' ');
  }

  static String _describeEvent(EventDTO event) {
    final parts = <String>[];

    if (event.id.trim().isNotEmpty) {
      parts.add('event_id=${event.id.trim()}');
    }

    for (final occurrence in event.occurrences) {
      final occurrenceId = occurrence.occurrenceId.trim();
      if (!occurrence.isSelected || occurrenceId.isEmpty) {
        continue;
      }
      parts.add('occurrence_id=$occurrenceId');
      break;
    }

    if (event.slug.trim().isNotEmpty) {
      parts.add('slug=${event.slug.trim()}');
    }

    return parts.join(' ');
  }
}
