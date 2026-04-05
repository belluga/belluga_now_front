part of '../partner_profile_module_data.dart';

class PartnerEventView {
  PartnerEventView({
    required this.eventIdValue,
    required this.occurrenceIdValue,
    required this.slugValue,
    required this.titleValue,
    this.eventTypeLabelValue,
    required this.startDateTimeValue,
    this.endDateTimeValue,
    required this.locationValue,
    this.venueIdValue,
    this.venueTitleValue,
    this.imageUriValue,
    List<PartnerSupportedEntityView>? artists,
  }) : artists = List<PartnerSupportedEntityView>.unmodifiable(
          artists ?? const <PartnerSupportedEntityView>[],
        );

  final MongoIDValue eventIdValue;
  final MongoIDValue occurrenceIdValue;
  final SlugValue slugValue;
  final PartnerProjectionRequiredTextValue titleValue;
  final PartnerProjectionOptionalTextValue? eventTypeLabelValue;
  final DateTimeValue startDateTimeValue;
  final DateTimeValue? endDateTimeValue;
  final PartnerProjectionRequiredTextValue locationValue;
  final MongoIDValue? venueIdValue;
  final PartnerProjectionOptionalTextValue? venueTitleValue;
  final ThumbUriValue? imageUriValue;
  final List<PartnerSupportedEntityView> artists;

  String get eventId => eventIdValue.value;
  String get occurrenceId => occurrenceIdValue.value;
  String get uniqueId => occurrenceId;
  String get slug => slugValue.value;
  String get title => titleValue.value;
  String? get eventTypeLabel {
    final value = eventTypeLabelValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
  DateTime get startDateTime {
    final date = startDateTimeValue.value;
    if (date == null) {
      throw StateError('startDateTime should not be null');
    }
    return TimezoneConverter.utcToLocal(date);
  }

  DateTime? get endDateTime {
    final date = endDateTimeValue?.value;
    if (date == null) {
      return null;
    }
    return TimezoneConverter.utcToLocal(date);
  }

  String get location => locationValue.value;
  String? get venueId {
    final value = venueIdValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get venueTitle {
    final value = venueTitleValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Uri? get imageUri => imageUriValue?.value;
  PartnerSupportedEntityView? get primaryArtist =>
      artists.isEmpty ? null : artists.first;
  String get artistNamesLabel => artists
      .map((artist) => artist.title.trim())
      .where((t) => t.isNotEmpty)
      .join(', ');
}
