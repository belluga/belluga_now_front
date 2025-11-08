import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_avatar_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_id_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_is_highlight_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_name_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/venue_event/venue_event_preview_dto.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

mixin VenueEventDtoMapper {
  VenueEventResume mapVenueEventResume(VenueEventPreviewDTO dto) {
    final title = TitleValue()..parse(dto.title);
    final imageUri = ThumbUriValue(
      defaultValue: Uri.parse(dto.imageUrl),
      isRequired: true,
    )..parse(dto.imageUrl);

    final startDate = DateTimeValue(isRequired: true)
      ..parse(dto.startDateTime.toIso8601String());

    final location = DescriptionValue()..parse(dto.location);
    final artistName = dto.artist.trim();
    final List<ArtistResume> artists;
    if (artistName.isEmpty) {
      artists = const [];
    } else {
      artists = [
        ArtistResume(
          idValue: ArtistIdValue()..parse('${dto.id}-$artistName'),
          nameValue: ArtistNameValue()..parse(artistName),
          avatarValue: ArtistAvatarValue(),
          isHighlightValue: ArtistIsHighlightValue()..parse('false'),
        ),
      ];
    }

    return VenueEventResume(
      slug: dto.id,
      titleValue: title,
      imageUriValue: imageUri,
      startDateTimeValue: startDate,
      locationValue: location,
      artists: artists,
    );
  }
}
