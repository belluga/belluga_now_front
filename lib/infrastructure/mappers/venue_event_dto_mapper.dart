import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_event_dto.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

mixin VenueEventDtoMapper {
  VenueEventResume mapVenueEventResume(HomeEventDTO dto) {
    final title = TitleValue()..parse(dto.title);
    final imageUri = ThumbUriValue(
      defaultValue: Uri.parse(dto.imageUrl),
      isRequired: true,
    )..parse(dto.imageUrl);

    final startDate = DateTimeValue(isRequired: true)
      ..parse(dto.startDateTime.toIso8601String());

    final location = DescriptionValue()..parse(dto.location);
    final artist = TitleValue()..parse(dto.artist);

    return VenueEventResume(
      slug: dto.id ?? VenueEventResume.slugify(dto.title),
      titleValue: title,
      imageUriValue: imageUri,
      startDateTimeValue: startDate,
      locationValue: location,
      artists: artist.value.isNotEmpty ? [artist.value] : const [],
    );
  }
}
