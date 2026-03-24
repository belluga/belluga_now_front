import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_avatar_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_genre_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_id_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_is_highlight_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_name_value.dart';

class EventArtistDTO {
  const EventArtistDTO({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.highlight,
    this.genres = const [],
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final bool? highlight;
  final List<String> genres;

  ArtistResume toDomain() {
    final avatarValue = ArtistAvatarValue();
    final normalizedAvatarUrl = avatarUrl?.trim();
    if (normalizedAvatarUrl != null && normalizedAvatarUrl.isNotEmpty) {
      avatarValue.parse(normalizedAvatarUrl);
    }

    return ArtistResume(
      idValue: ArtistIdValue()..parse(id),
      nameValue: ArtistNameValue()..parse(name),
      avatarValue: avatarValue,
      isHighlightValue: ArtistIsHighlightValue()
        ..parse((highlight ?? false).toString()),
      genreValues: genres
          .where((genre) => genre.trim().isNotEmpty)
          .map((genre) => ArtistGenreValue()..parse(genre))
          .toList(growable: false),
    );
  }
}
