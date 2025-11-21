import 'package:belluga_now/infrastructure/artist/dtos/artist_resume_dto.dart';
import 'package:belluga_now/infrastructure/courses/dtos/thumb_dto.dart';
import 'package:belluga_now/infrastructure/map/dtos/city_coordinate_dto.dart';
import 'package:belluga_now/infrastructure/schedule/dtos/event_action_dto.dart';

class EventDto {
  final String id;
  final String slug;
  final String type;
  final String title;
  final String content;
  final String location;
  final ThumbDto? thumb;
  final String startTime;
  final String? endTime;
  final Map<String, dynamic>? venue; // Partner as venue
  final List<ArtistResumeDto> artists;
  final List<Map<String, dynamic>>?
      participants; // Event participants with roles
  final List<EventActionDto> actions;
  final CityCoordinateDto? coordinate;
  final bool isConfirmed;
  final int totalConfirmed;
  final List<Map<String, dynamic>>? receivedInvites;
  final List<Map<String, dynamic>>? sentInvites;
  final List<Map<String, dynamic>>? friendsGoing;

  EventDto({
    required this.id,
    required this.slug,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    this.thumb,
    required this.startTime,
    this.endTime,
    this.venue,
    required this.artists,
    this.participants,
    required this.actions,
    this.coordinate,
    this.isConfirmed = false,
    this.totalConfirmed = 0,
    this.receivedInvites,
    this.sentInvites,
    this.friendsGoing,
  });

  factory EventDto.fromJson(Map<String, dynamic> json) {
    return EventDto(
      id: json['id'] as String,
      slug: json['slug'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      location: json['location'] as String,
      thumb: json['thumb'] != null
          ? ThumbDto.fromJson(json['thumb'] as Map<String, dynamic>)
          : null,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String?,
      venue: json['venue'] as Map<String, dynamic>?,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => ArtistResumeDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => EventActionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      coordinate: json['coordinate'] != null
          ? CityCoordinateDto.fromJson(
              json['coordinate'] as Map<String, dynamic>)
          : null,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'type': type,
      'title': title,
      'content': content,
      'location': location,
      'thumb': thumb?.toJson(),
      'start_time': startTime,
      'end_time': endTime,
      'artists': artists.map((e) => e.toJson()).toList(),
      'actions': actions.map((e) => e.toJson()).toList(),
      'coordinate': coordinate?.toJson(),
      'is_confirmed': isConfirmed,
      'total_confirmed': totalConfirmed,
      'received_invites': receivedInvites,
      'sent_invites': sentInvites,
      'friends_going': friendsGoing,
    };
  }
}
