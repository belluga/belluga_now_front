import 'package:belluga_now/domain/artist/value_objects/artist_avatar_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_genre_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_id_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_is_highlight_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_name_value.dart';

class ArtistResume {
  ArtistResume({
    required this.idValue,
    required this.nameValue,
    required this.avatarValue,
    required this.isHighlightValue,
    required List<ArtistGenreValue> genreValues,
  }) : genreValues = List.unmodifiable(genreValues);

  final ArtistIdValue idValue;
  final ArtistNameValue nameValue;
  final ArtistAvatarValue avatarValue;
  final ArtistIsHighlightValue isHighlightValue;
  final List<ArtistGenreValue> genreValues;

  String get id => idValue.value;
  String get displayName => nameValue.value;
  Uri? get avatarUri => avatarValue.value;
  bool get isHighlight => isHighlightValue.value;
  List<String> get genres =>
      genreValues.map((genre) => genre.value).toList(growable: false);
}
