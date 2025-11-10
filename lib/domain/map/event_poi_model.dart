import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_address_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_description_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_priority_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';

class EventPoiModel extends CityPoiModel {
  EventPoiModel._({
    required this.event,
    required super.idValue,
    required super.nameValue,
    required super.descriptionValue,
    required super.addressValue,
    required super.coordinate,
    required super.priorityValue,
    super.tagValues,
  }) : super(
          category: CityPoiCategory.culture,
          isDynamic: true,
        );

  final EventModel event;

  factory EventPoiModel.fromEvent(EventModel event) {
    final coordinate = event.coordinate;
    if (coordinate == null) {
      throw ArgumentError('Event requires coordinate to be mapped as a POI');
    }

    final rawId = event.id.value;
    final rawTitle = event.title.value;
    final idSource =
        rawId.isNotEmpty ? rawId : (rawTitle.isNotEmpty ? rawTitle : 'event');
    final idValue = CityPoiIdValue()..parse('event_$idSource');

    final safeTitle = rawTitle.isNotEmpty ? rawTitle : 'Experiência imperdível';
    final nameValue = CityPoiNameValue()..parse(safeTitle);

    final plainContent = _plainText(event.content);
    final descriptionSeed = plainContent.isNotEmpty
        ? plainContent
        : (event.location.value.isNotEmpty ? event.location.value : safeTitle);

    final descriptionValue = CityPoiDescriptionValue()..parse(descriptionSeed);

    final resolvedAddress =
        event.location.value.isNotEmpty ? event.location.value : 'Guarapari';
    final addressValue = CityPoiAddressValue()..parse(resolvedAddress);

    final priorityValue = PoiPriorityValue()
      ..parse(_priorityForEvent(event).toString());

    final tagValues = _buildTagValues(event);

    return EventPoiModel._(
      event: event,
      idValue: idValue,
      nameValue: nameValue,
      descriptionValue: descriptionValue,
      addressValue: addressValue,
      coordinate: coordinate,
      priorityValue: priorityValue,
      tagValues: tagValues,
    );
  }

  static int _priorityForEvent(EventModel event) {
    final start = event.dateTimeStart.value;
    if (start == null) {
      return 240;
    }
    final now = DateTime.now();
    final diffMinutes = start.difference(now).inMinutes;
    if (diffMinutes <= 0) {
      return 20;
    }
    if (diffMinutes <= 180) {
      return 45;
    }
    if (diffMinutes <= 720) {
      return 80;
    }
    if (diffMinutes <= 1440) {
      return 120;
    }
    return 200 + (diffMinutes ~/ 60);
  }

  static List<PoiTagValue> _buildTagValues(EventModel event) {
    final rawTags = <String>{
      'evento',
      event.type.slug.value,
      event.type.name.value,
      event.location.value,
      ...event.artists.map((artist) => artist.nameValue.value),
    };

    return rawTags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .map((tag) => PoiTagValue()..parse(tag))
        .toList(growable: false);
  }

  static String _plainText(HTMLContentValue value) {
    final html = value.value;
    if (html == null || html.isEmpty) {
      return '';
    }
    final withoutTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
