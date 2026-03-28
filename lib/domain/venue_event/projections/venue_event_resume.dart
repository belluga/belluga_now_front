import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/gamification/mission_resume.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_tag_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

typedef VenueEventResumePrimString = String;
typedef VenueEventResumePrimInt = int;
typedef VenueEventResumePrimBool = bool;
typedef VenueEventResumePrimDouble = double;
typedef VenueEventResumePrimDateTime = DateTime;
typedef VenueEventResumePrimDynamic = dynamic;

class VenueEventResume {
  VenueEventResume({
    required this.idValue,
    required this.slugValue,
    required this.titleValue,
    required this.imageUriValue,
    required this.startDateTimeValue,
    required this.locationValue,
    required this.artists,
    required this.tagValues,
    this.coordinate,
    this.mission,
  });

  final MongoIDValue idValue;
  final SlugValue slugValue;
  final TitleValue titleValue;
  final ThumbUriValue imageUriValue;
  final DateTimeValue startDateTimeValue;
  final DescriptionValue locationValue;
  final List<ArtistResume> artists;
  final List<VenueEventTagValue> tagValues;
  final CityCoordinate? coordinate;
  final MissionResume? mission;
  static final Uri _localPlaceholderUri =
      Uri.parse('asset://event-placeholder');

  VenueEventResumePrimString get id => idValue.value;
  VenueEventResumePrimString get slug => slugValue.value;
  VenueEventResumePrimString get title => titleValue.value;
  Uri get imageUri => imageUriValue.value;
  VenueEventResumePrimDateTime get startDateTime {
    final date = startDateTimeValue.value;
    if (date == null) {
      throw StateError('startDateTime should not be null');
    }
    return date;
  }

  VenueEventResumePrimString get location => locationValue.value;
  CityCoordinate? get coordinateValue => coordinate;
  VenueEventResumePrimBool get hasArtists => artists.isNotEmpty;
  ArtistResume? get primaryArtist => hasArtists ? artists.first : null;
  List<VenueEventResumePrimString> get tags =>
      tagValues.map((tagValue) => tagValue.value).toList(growable: false);
  VenueEventResumePrimString get artistNamesLabel =>
      artists.map((artist) => artist.displayName).join(', ');

  static VenueEventResumePrimString slugify(Object value) {
    final rawValue =
        value is VenueEventTagValue ? value.value : value.toString();
    final slug = rawValue.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static Uri resolvePreferredImageUri(
    EventModel event, {
    ThumbUriValue? settingsDefaultImageValue,
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

    if (settingsDefaultImageValue != null &&
        settingsDefaultImageValue.value.toString().trim().isNotEmpty) {
      return settingsDefaultImageValue.value;
    }

    return _localPlaceholderUri;
  }

  factory VenueEventResume.fromScheduleEvent(
    EventModel event,
    Object fallbackImage,
  ) {
    final fallbackImageValue = _coerceFallbackImageValue(fallbackImage);
    final slugSource = event.slug;
    final slug = SlugValue()
      ..parse(
        slugSource.isNotEmpty
            ? slugSource
            : VenueEventResume.slugify(event.title.value),
      );

    final preferredImageUri = resolvePreferredImageUri(
      event,
      settingsDefaultImageValue: fallbackImageValue,
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
      idValue: event.id,
      slugValue: slug,
      titleValue: event.title,
      imageUriValue: thumb,
      startDateTimeValue: startValue,
      locationValue: event.location,
      artists: event.artists,
      tagValues: event.taxonomyTags
          .map((tag) => VenueEventTagValue(tag))
          .toList(growable: false),
      coordinate: event.coordinate,
      mission: null, // TODO: Map from EventModel when available
    );
  }

  static ThumbUriValue _coerceFallbackImageValue(Object raw) {
    if (raw is ThumbUriValue) {
      return raw;
    }
    if (raw is Uri) {
      final thumb = ThumbUriValue(defaultValue: raw, isRequired: true)
        ..parse(raw.toString());
      return thumb;
    }
    throw ArgumentError.value(
      raw,
      'fallbackImage',
      'Expected Uri or ThumbUriValue',
    );
  }
}
