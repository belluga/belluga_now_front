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
  });

  final ArtistIdValue idValue;
  final ArtistNameValue nameValue;
  final ArtistAvatarValue avatarValue;
  final ArtistIsHighlightValue isHighlightValue;

  String get id => idValue.value;
  String get displayName => nameValue.value;
  Uri? get avatarUri => avatarValue.value;
  bool get isHighlight => isHighlightValue.value;
}
