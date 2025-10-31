import 'package:belluga_now/domain/schedule/value_objects/event_artist_is_highlight_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_artist_name_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_artist_dto.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class EventArtistModel {
  EventArtistModel({
    required this.name,
    required this.avatarUrl,
    required this.isHighlight,
  });

  final EventArtistNameValue name;
  final URIValue avatarUrl;
  final EventArtistIsHighlightValue isHighlight;

  factory EventArtistModel.fromDTO(EventArtistDTO dto) {
    final name = EventArtistNameValue()..parse(dto.name);
    final avatar = URIValue(
      defaultValue: Uri.parse(
        'https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308',
      ),
    )..tryParse(dto.avatarUrl);
    final highlight = EventArtistIsHighlightValue()
      ..parse((dto.highlight ?? false).toString());

    return EventArtistModel(
      name: name,
      avatarUrl: avatar,
      isHighlight: highlight,
    );
  }
}
