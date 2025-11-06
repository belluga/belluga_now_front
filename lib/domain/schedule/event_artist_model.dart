import 'package:belluga_now/domain/schedule/value_objects/event_artist_is_highlight_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_artist_name_value.dart';
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
}
