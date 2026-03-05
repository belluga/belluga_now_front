import 'package:belluga_now/infrastructure/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_type_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/thumb_dto.dart';

class EventDTO {
  const EventDTO({
    required this.id,
    required this.slug,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    this.venue,
    this.latitude,
    this.longitude,
    this.thumb,
    required this.dateTimeStart,
    this.dateTimeEnd,
    required this.artists,
    this.isConfirmed = false,
    this.totalConfirmed = 0,
    this.receivedInvites,
    this.sentInvites,
    this.friendsGoing,
    this.tags = const [],
  });

  final String id;
  final String slug;
  final EventTypeDTO type;
  final String title;
  final String content;
  final String location;
  final Map<String, dynamic>? venue;
  final double? latitude;
  final double? longitude;
  final ThumbDTO? thumb;
  final String dateTimeStart;
  final String? dateTimeEnd;
  final List<EventArtistDTO> artists;
  final bool isConfirmed;
  final int totalConfirmed;
  final List<Map<String, dynamic>>? receivedInvites;
  final List<Map<String, dynamic>>? sentInvites;
  final List<Map<String, dynamic>>? friendsGoing;
  final List<String> tags;

  factory EventDTO.fromJson(Map<String, dynamic> json) {
    final typePayload = _asMap(json['type']);
    final venuePayload = _asMap(json['venue']);
    final locationPayload = _asMap(json['location']);
    final geoLocationPayload = _asMap(json['geo_location']);
    final location = _resolveLocation(
      rawLocation: json['location'],
      venuePayload: venuePayload,
    );
    final coordinates = _resolveCoordinates(
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      locationPayload: locationPayload,
      geoLocationPayload: geoLocationPayload,
    );

    return EventDTO(
      id: _asString(json['id']) ??
          _asString(json['event_id']) ??
          _asString(json['occurrence_id']) ??
          '',
      slug: _asString(json['slug']) ?? '',
      type: EventTypeDTO(
        id: _asString(typePayload['id']) ?? '',
        name: _asString(typePayload['name']) ?? '',
        slug: _asString(typePayload['slug']) ?? '',
        description: _asString(typePayload['description']) ?? '',
        icon: _asNullableString(typePayload['icon']),
        color: _asNullableString(typePayload['color']),
      ),
      title: _asString(json['title']) ?? '',
      content: _asString(json['content']) ?? '',
      venue: venuePayload.isEmpty ? null : venuePayload,
      location: location,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      thumb: _asMap(json['thumb']).isNotEmpty
          ? ThumbDTO.fromJson(_asMap(json['thumb']))
          : null,
      dateTimeStart: _asString(json['date_time_start']) ??
          _asString(json['starts_at']) ??
          _asString(json['start_time']) ??
          '',
      dateTimeEnd: _asNullableString(json['date_time_end']) ??
          _asNullableString(json['ends_at']) ??
          _asNullableString(json['end_time']),
      artists: (json['artists'] as List<dynamic>? ?? [])
          .map(
            (artist) => EventArtistDTO(
              id: _asString(_asMap(artist)['id']) ?? '',
              name: _asString(_asMap(artist)['display_name']) ??
                  _asString(_asMap(artist)['name']) ??
                  '',
              avatarUrl: _asNullableString(_asMap(artist)['avatar_url']),
              highlight: _asMap(artist)['highlight'] == null
                  ? null
                  : _asBool(_asMap(artist)['highlight']),
            ),
          )
          .toList(),
      isConfirmed: _asBool(json['is_confirmed']),
      totalConfirmed: _asInt(json['total_confirmed']),
      receivedInvites: _asMapList(json['received_invites']),
      sentInvites: _asMapList(json['sent_invites']),
      friendsGoing: _asMapList(json['friends_going']),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static List<Map<String, dynamic>>? _asMapList(dynamic value) {
    if (value is! List) {
      return null;
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static String _resolveLocation({
    required dynamic rawLocation,
    required Map<String, dynamic> venuePayload,
  }) {
    final locationAsString = _asString(rawLocation);
    if (locationAsString != null) {
      return locationAsString;
    }

    final locationMap = _asMap(rawLocation);
    final locationFromMap = _asString(locationMap['display_name']) ??
        _asString(locationMap['name']) ??
        _asString(locationMap['label']) ??
        _asString(locationMap['address']) ??
        _asString(locationMap['address_line']);
    if (locationFromMap != null) {
      return locationFromMap;
    }

    return _asString(venuePayload['display_name']) ??
        _asString(venuePayload['name']) ??
        '';
  }

  static ({double? latitude, double? longitude}) _resolveCoordinates({
    required double? latitude,
    required double? longitude,
    required Map<String, dynamic> locationPayload,
    required Map<String, dynamic> geoLocationPayload,
  }) {
    if (latitude != null && longitude != null) {
      return (latitude: latitude, longitude: longitude);
    }

    final locationGeo = _asMap(locationPayload['geo']);
    final geoSource = locationGeo.isNotEmpty ? locationGeo : geoLocationPayload;
    final coordinates = geoSource['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final lng = _asDouble(coordinates[0]);
      final lat = _asDouble(coordinates[1]);
      if (lat != null && lng != null) {
        return (latitude: lat, longitude: lng);
      }
    }

    return (latitude: latitude, longitude: longitude);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'type': {
        'id': type.id,
        'name': type.name,
        'slug': type.slug,
        'description': type.description,
        'icon': type.icon,
        'color': type.color,
      },
      'title': title,
      'content': content,
      'location': location,
      'venue': venue,
      'latitude': latitude,
      'longitude': longitude,
      'thumb': thumb != null
          ? {
              'type': thumb!.type,
              'data': thumb!.data,
            }
          : null,
      'date_time_start': dateTimeStart,
      'date_time_end': dateTimeEnd,
      'artists': artists
          .map(
            (artist) => {
              'id': artist.id,
              'name': artist.name,
              'avatar_url': artist.avatarUrl,
              'highlight': artist.highlight,
            },
          )
          .toList(),
      'is_confirmed': isConfirmed,
      'total_confirmed': totalConfirmed,
      'received_invites': receivedInvites,
      'sent_invites': sentInvites,
      'friends_going': friendsGoing,
      'tags': tags,
    };
  }
}
