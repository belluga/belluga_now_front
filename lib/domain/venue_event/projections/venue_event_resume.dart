import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/gamification/mission_resume.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class VenueEventResume {
  VenueEventResume({
    required this.id,
    required this.slug,
    required this.titleValue,
    required this.imageUriValue,
    required this.startDateTimeValue,
    required this.locationValue,
    required this.artists,
    required this.tags,
    this.coordinate,
    this.mission,
  });

  final String id;
  final String slug;
  final TitleValue titleValue;
  final ThumbUriValue imageUriValue;
  final DateTimeValue startDateTimeValue;
  final DescriptionValue locationValue;
  final List<ArtistResume> artists;
  final List<String> tags;
  final CityCoordinate? coordinate;
  final MissionResume? mission;
  static final Uri _localPlaceholderUri =
      Uri.parse('asset://event-placeholder');

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
  CityCoordinate? get coordinateValue => coordinate;
  bool get hasArtists => artists.isNotEmpty;
  ArtistResume? get primaryArtist => hasArtists ? artists.first : null;
  String get artistNamesLabel =>
      artists.map((artist) => artist.displayName).join(', ');

  static String slugify(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static Uri resolvePreferredImageUri(
    EventModel event, {
    Uri? settingsDefaultImageUri,
  }) {
    final eventCover = event.thumb?.thumbUri.value;
    if (eventCover != null) {
      return eventCover;
    }

    for (final artist in event.artists) {
      final artistCover = artist.avatarUri;
      if (artistCover != null) {
        return artistCover;
      }
    }

    final hostCover = event.venue?.heroImageUri ?? event.venue?.logoImageUri;
    if (hostCover != null) {
      return hostCover;
    }

    if (settingsDefaultImageUri != null &&
        settingsDefaultImageUri.toString().trim().isNotEmpty) {
      return settingsDefaultImageUri;
    }

    return _localPlaceholderUri;
  }

  factory VenueEventResume.fromScheduleEvent(
    EventModel event,
    Uri fallbackImage,
  ) {
    final slugSource = event.slug;
    final slug = slugSource.isNotEmpty
        ? slugSource
        : VenueEventResume.slugify(event.title.value);

    final preferredImageUri = resolvePreferredImageUri(
      event,
      settingsDefaultImageUri: fallbackImage,
    );
    final thumb =
        ThumbUriValue(defaultValue: preferredImageUri, isRequired: true)
          ..parse(preferredImageUri.toString());

    final startDateTime = event.dateTimeStart.value;
    if (startDateTime == null) {
      throw StateError('EventModel.dateTimeStart must be defined');
    }

    final startValue = DateTimeValue(isRequired: true)
      ..parse(startDateTime.toIso8601String());

    return VenueEventResume(
      id: event.id.value,
      slug: slug,
      titleValue: event.title,
      imageUriValue: thumb,
      startDateTimeValue: startValue,
      locationValue: event.location,
      artists: event.artists,
      tags: event.taxonomyTags,
      coordinate: event.coordinate,
      mission: null, // TODO: Map from EventModel when available
    );
  }
}
