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
    return EventDTO(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? '',
      type: EventTypeDTO(
        id: json['type']['id'] as String,
        name: json['type']['name'] as String? ?? '',
        slug: json['type']['slug'] as String? ?? '',
        description: json['type']['description'] as String? ?? '',
        icon: json['type']['icon'] as String?,
        color: json['type']['color'] as String?,
      ),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      venue: json['venue'] as Map<String, dynamic>?,
      location: json['location'] as String? ??
          (json['venue'] is Map<String, dynamic>
              ? (json['venue'] as Map<String, dynamic>)['display_name'] as String?
              : null) ??
          '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      thumb: json['thumb'] != null
          ? ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>)
          : null,
      dateTimeStart: json['date_time_start'] as String? ??
          json['start_time'] as String? ??
          '',
      dateTimeEnd:
          json['date_time_end'] as String? ?? json['end_time'] as String?,
      artists: (json['artists'] as List<dynamic>? ?? [])
          .map(
            (artist) => EventArtistDTO(
              id: artist['id'] as String,
              name: artist['display_name'] as String? ??
                  artist['name'] as String? ??
                  '',
              avatarUrl: artist['avatar_url'] as String?,
              highlight: artist['highlight'] as bool?,
            ),
          )
          .toList(),
      isConfirmed: json['is_confirmed'] as bool? ?? false,
      totalConfirmed: json['total_confirmed'] as int? ?? 0,
      receivedInvites: (json['received_invites'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      sentInvites: (json['sent_invites'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      friendsGoing: (json['friends_going'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
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
