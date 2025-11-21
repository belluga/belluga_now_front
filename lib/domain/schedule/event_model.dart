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
import 'package:belluga_now/infrastructure/schedule/dtos/event_dto.dart';
import 'package:belluga_now/infrastructure/invites/dtos/invite_dto.dart';
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

  // Confirmation state
  final EventIsConfirmedValue isConfirmedValue;
  final DateTime? confirmedAt;

  // Received invites (who invited me)
  final List<InviteModel>? receivedInvites;

  // Sent invites with status tracking
  final List<SentInviteStatus>? sentInvites;

  // Social proof
  final List<FriendResume>? friendsGoing;
  final EventTotalConfirmedValue totalConfirmedValue;

  bool get isConfirmed => isConfirmedValue.value;
  int get totalConfirmed => totalConfirmedValue.value;

  EventModel({
    required this.id,
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
    required this.isConfirmedValue,
    this.confirmedAt,
    this.receivedInvites,
    this.sentInvites,
    this.friendsGoing,
    required this.totalConfirmedValue,
  });

  factory EventModel.fromDto(EventDto dto) {
    return EventModel(
      id: MongoIDValue()..parse(dto.id),
      type: EventTypeModel(
        id: MongoIDValue()..parse(dto.type),
        name: TitleValue()..parse(dto.type),
        slug: SlugValue()..parse(dto.type),
        description: DescriptionValue()..parse(dto.type),
        icon: SlugValue()..parse('default-icon'),
        color: ColorValue(defaultValue: const Color(0xFF000000))
          ..parse('#000000'),
      ),
      title: TitleValue()..parse(dto.title),
      content: HTMLContentValue()..parse(dto.content),
      location: DescriptionValue()..parse(dto.location),
      thumb: dto.thumb != null ? ThumbModel.fromDto(dto.thumb!) : null,
      dateTimeStart: DateTimeValue()..parse(dto.startTime),
      dateTimeEnd:
          dto.endTime != null ? (DateTimeValue()..parse(dto.endTime!)) : null,
      venue: dto.venue != null ? PartnerResume.fromDto(dto.venue!) : null,
      artists: dto.artists.map((e) => ArtistResume.fromDto(e)).toList(),
      participants:
          dto.participants?.map((e) => EventParticipant.fromDto(e)).toList() ??
              [],
      actions: dto.actions.map((e) => EventActionModel.fromDto(e)).toList(),
      coordinate: dto.coordinate != null
          ? CityCoordinate(
              latitudeValue: LatitudeValue()
                ..parse(dto.coordinate!.latitude.toString()),
              longitudeValue: LongitudeValue()
                ..parse(dto.coordinate!.longitude.toString()),
            )
          : null,
      isConfirmedValue: EventIsConfirmedValue()
        ..parse(dto.isConfirmed.toString()),
      totalConfirmedValue: EventTotalConfirmedValue()
        ..parse(dto.totalConfirmed.toString()),
      receivedInvites: dto.receivedInvites
          ?.map((e) => InviteModel.fromDto(InviteDto.fromJson(e)))
          .toList(),
      sentInvites:
          dto.sentInvites?.map((e) => SentInviteStatus.fromDto(e)).toList(),
      friendsGoing:
          dto.friendsGoing?.map((e) => FriendResume.fromDto(e)).toList(),
    );
  }
}
