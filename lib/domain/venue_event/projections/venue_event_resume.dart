import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class VenueEventResume {
  VenueEventResume({
    required this.slug,
    required this.titleValue,
    required this.imageUriValue,
    required this.startDateTimeValue,
    required this.locationValue,
    required this.artists,
  });

  final String slug;
  final TitleValue titleValue;
  final ThumbUriValue imageUriValue;
  final DateTimeValue startDateTimeValue;
  final DescriptionValue locationValue;
  final List<String> artists;

  String get title => titleValue.value;
  Uri get imageUri => imageUriValue.value;
  DateTime get startDateTime {
    final date = startDateTimeValue.value;
    if (date == null) {
      throw StateError('startDateTime should not be null');
    }
    return date;
  }

  String get location => locationValue.value;
  String get primaryArtist => artists.isNotEmpty ? artists.first : '';
  bool get hasArtists => artists.isNotEmpty;

  static String slugify(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  factory VenueEventResume.fromScheduleEvent(
    EventModel event,
    Uri fallbackImage,
  ) {
    final slugSource = event.id.value;
    final slug = slugSource.isNotEmpty
        ? slugSource
        : VenueEventResume.slugify(event.title.value);

    final thumb = event.thumb?.thumbUri ??
        (ThumbUriValue(
          defaultValue: fallbackImage,
          isRequired: true,
        )..parse(fallbackImage.toString()));

    final artistName = event.artists.isNotEmpty
        ? event.artists.first.name.value
        : 'Belluga Now';

    final artistNames = event.artists.isNotEmpty
        ? event.artists.map((artist) => artist.name.value).toList()
        : <String>[];

    final startDateTime = event.dateTimeStart.value;
    if (startDateTime == null) {
      throw StateError('EventModel.dateTimeStart must be defined');
    }

    final startValue = DateTimeValue(isRequired: true)
      ..parse(startDateTime.toIso8601String());

    return VenueEventResume(
      slug: slug,
      titleValue: event.title,
      imageUriValue: thumb,
      startDateTimeValue: startValue,
      locationValue: event.location,
      artists: artistNames.isNotEmpty ? artistNames : [artistName],
    );
  }
}
