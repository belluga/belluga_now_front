import 'package:belluga_now/domain/artist/value_objects/artist_avatar_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_id_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_is_highlight_value.dart';
import 'package:belluga_now/domain/artist/value_objects/artist_name_value.dart';

class ArtistResume {
  ArtistResume({
    required this.idValue,
    required this.nameValue,
    required this.avatarValue,
    required this.isHighlightValue,
    required this.genres,
  });

  final ArtistIdValue idValue;
  final ArtistNameValue nameValue;
  final ArtistAvatarValue avatarValue;
  final ArtistIsHighlightValue isHighlightValue;
  final List<String> genres;

  String get id => idValue.value;
  String get displayName => nameValue.value;
  Uri? get avatarUri => avatarValue.value;
  bool get isHighlight => isHighlightValue.value;

  factory ArtistResume.fromPrimitives({
    required String id,
    required String name,
    String? avatarUrl,
    bool isHighlight = false,
    List<String> genres = const [],
  }) {
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
        ..parse(isHighlight.toString()),
      genres: genres,
    );
  }
}
