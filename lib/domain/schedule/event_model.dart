import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/schedule/event_participant.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/artist/artist_resume_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:flutter/material.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/courses/value_objects/slug_value.dart';

import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';

class EventModel {
  final MongoIDValue id;
  final SlugValue slugValue; // Added slugValue
  final EventTypeModel type;
  final TitleValue title;
  final HTMLContentValue content;
  final DescriptionValue location;
  final PartnerResume? venue; // Where the event happens
  final ThumbModel? thumb;
  final DateTimeValue dateTimeStart;
  final DateTimeValue? dateTimeEnd;
  final List<ArtistResume> artists; // Keep for backward compatibility
  final List<EventParticipant> participants; // New: all participants with roles
  final List<EventActionModel> actions;
  final CityCoordinate? coordinate;
  final List<String> tags;

  // Confirmation state
  final EventIsConfirmedValue isConfirmedValue;
  final DateTime? confirmedAt;

  // Received invites (who invited me)
  final List<InviteModel>? receivedInvites;

  // Sent invites with status tracking
  final List<SentInviteStatus>? sentInvites;

  // Social proof
  final List<EventFriendResume>? friendsGoing;
  final EventTotalConfirmedValue totalConfirmedValue;

  bool get isConfirmed => isConfirmedValue.value;
  int get totalConfirmed => totalConfirmedValue.value;
  String get slug => slugValue.value; // Added getter
  List<String> get taxonomyTags {
    final cleaned = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    if (cleaned.isNotEmpty) return cleaned;

    final artistGenres = artists
        .expand((artist) => artist.genres)
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    return artistGenres;
  }

  EventModel({
    required this.id,
    required this.slugValue,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    this.venue,
    required this.thumb,
    required this.dateTimeStart,
    required this.dateTimeEnd,
    required this.artists,
    required this.participants,
    required this.actions,
    required this.coordinate,
    required this.tags,
    required this.isConfirmedValue,
    this.confirmedAt,
    this.receivedInvites,
    this.sentInvites,
    this.friendsGoing,
    required this.totalConfirmedValue,
  });

  factory EventModel.fromDto(EventDTO dto) {
    final thumb = dto.thumb != null ? ThumbModel.fromDalDto(dto.thumb!) : null;
    final coordinate = (dto.latitude != null && dto.longitude != null)
        ? CityCoordinate(
            latitudeValue: LatitudeValue()
              ..parse(dto.latitude!.toString()),
            longitudeValue: LongitudeValue()
              ..parse(dto.longitude!.toString()),
          )
        : null;
    final artists = dto.artists
        .map(
        (artist) => ArtistResume.fromDto(
              ArtistResumeDto(
                id: artist.id,
                name: artist.name,
                avatarUrl: artist.avatarUrl,
                isHighlight: artist.highlight ?? false,
                genres: artist.genres,
              ),
            ),
        )
        .toList();
    final participants = dto.participants
            ?.map((e) => EventParticipant.fromDto(e))
            .toList() ??
        [];

    return EventModel(
      id: MongoIDValue()..parse(dto.id),
      slugValue: SlugValue()..parse(dto.slug), // Map slug
      type: EventTypeModel(
        id: MongoIDValue()..parse(dto.type.id),
        name: TitleValue(minLenght: 1)..parse(dto.type.name),
        slug: SlugValue()..parse(dto.type.slug),
        description: DescriptionValue()..parse(dto.type.description),
        icon: SlugValue()..parse(dto.type.icon ?? 'default-icon'),
        color: ColorValue(defaultValue: const Color(0xFF000000))
          ..parse(dto.type.color ?? '#000000'),
      ),
      title: TitleValue()..parse(dto.title),
      content: HTMLContentValue()..parse(dto.content),
      // Location strings in mocks are short (e.g., city names); allow min length 1.
      location: DescriptionValue(minLenght: 1)..parse(dto.location),
      thumb: thumb,
      dateTimeStart: DateTimeValue()..parse(dto.dateTimeStart),
      dateTimeEnd: dto.dateTimeEnd != null
          ? (DateTimeValue()..parse(dto.dateTimeEnd!))
          : null,
      venue: dto.venue != null ? PartnerResume.fromDto(dto.venue!) : null,
      artists: artists,
      participants: participants,
      actions: dto.actions.map((e) => EventActionModel.fromDto(e)).toList(),
      coordinate: coordinate,
      tags: dto.tags,
      isConfirmedValue: EventIsConfirmedValue()
        ..parse(dto.isConfirmed.toString()),
      totalConfirmedValue: EventTotalConfirmedValue()
        ..parse(dto.totalConfirmed.toString()),
      receivedInvites: dto.receivedInvites?.map((e) {
        final inviteMap = Map<String, dynamic>.from(e);
        if (inviteMap['event_id'] == null) {
          inviteMap['event_id'] = dto.id;
        }
        return InviteModel.fromDto(InviteDto.fromJson(inviteMap));
      }).toList(),
      sentInvites:
          dto.sentInvites?.map((e) => SentInviteStatus.fromDto(e)).toList(),
      friendsGoing: dto.friendsGoing
          ?.map((friend) => EventFriendResume.fromDto(friend))
          .toList(),
    );
  }
}
