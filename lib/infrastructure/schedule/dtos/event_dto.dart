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
  final List<ArtistResumeDto> artists;
  final List<EventActionDto> actions;
  final CityCoordinateDto? coordinate;

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
    required this.artists,
    required this.actions,
    this.coordinate,
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
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => ArtistResumeDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => EventActionDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      coordinate: json['coordinate'] != null
          ? CityCoordinateDto.fromJson(
              json['coordinate'] as Map<String, dynamic>)
          : null,
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
    };
  }
}
