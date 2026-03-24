import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_avatar_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_genre_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_id_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_is_highlight_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_name_value.dart';

class ArtistResumeDto {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isHighlight;
  final List<String> genres;

  ArtistResumeDto({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.isHighlight,
    this.genres = const [],
  });

  factory ArtistResumeDto.fromJson(Map<String, dynamic> json) {
    return ArtistResumeDto(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      isHighlight: json['is_highlight'] as bool? ?? false,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'is_highlight': isHighlight,
      'genres': genres,
    };
  }

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
      isHighlightValue: ArtistIsHighlightValue()..parse(isHighlight.toString()),
      genreValues: genres
          .where((genre) => genre.trim().isNotEmpty)
          .map((genre) => ArtistGenreValue()..parse(genre))
          .toList(growable: false),
    );
  }
}
