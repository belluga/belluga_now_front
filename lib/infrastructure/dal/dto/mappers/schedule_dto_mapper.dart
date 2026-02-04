import 'package:belluga_now/domain/artist/artist_resume.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_item_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_item_dto.dart';
import 'package:flutter/material.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

import 'artist_dto_mapper.dart';
import 'invite_dto_mapper.dart';
import 'invite_status_dto_mapper.dart';
import 'partner_dto_mapper.dart';
import 'thumb_dto_mapper.dart';

mixin ScheduleDtoMapper
    on InviteDtoMapper,
        ThumbDtoMapper,
        ArtistDtoMapper,
        PartnerDtoMapper,
        InviteStatusDtoMapper {
  EventModel mapEventDto(EventDTO dto) {
    final ThumbModel? thumb = dto.thumb != null ? mapThumbDto(dto.thumb!) : null;
    final CityCoordinate? coordinate =
        (dto.latitude != null && dto.longitude != null)
            ? CityCoordinate(
                latitudeValue: LatitudeValue()
                  ..parse(dto.latitude!.toString()),
                longitudeValue: LongitudeValue()
                  ..parse(dto.longitude!.toString()),
              )
            : null;
    final List<ArtistResume> artists =
        dto.artists.map(mapEventArtistDto).toList();
    final PartnerResume? venue =
        dto.venue != null ? mapPartnerResume(dto.venue!) : null;

    final List<InviteModel>? receivedInvites = dto.receivedInvites?.map((e) {
      final inviteMap = Map<String, dynamic>.from(e);
      inviteMap.putIfAbsent('event_id', () => dto.id);
      return mapInviteDto(InviteDto.fromJson(inviteMap));
    }).toList();

    final List<SentInviteStatus>? sentInvites =
        dto.sentInvites?.map(mapSentInviteStatus).toList();
    final List<EventFriendResume>? friendsGoing =
        dto.friendsGoing?.map(mapEventFriendResume).toList();

    return EventModel(
      id: MongoIDValue()..parse(dto.id),
      slugValue: SlugValue()..parse(dto.slug),
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
      location: DescriptionValue(minLenght: 1)..parse(dto.location),
      thumb: thumb,
      dateTimeStart: DateTimeValue()..parse(dto.dateTimeStart),
      dateTimeEnd: dto.dateTimeEnd != null
          ? (DateTimeValue()..parse(dto.dateTimeEnd!))
          : null,
      venue: venue,
      artists: artists,
      coordinate: coordinate,
      tags: dto.tags,
      isConfirmedValue: EventIsConfirmedValue()
        ..parse(dto.isConfirmed.toString()),
      totalConfirmedValue: EventTotalConfirmedValue()
        ..parse(dto.totalConfirmed.toString()),
      receivedInvites: receivedInvites,
      sentInvites: sentInvites,
      friendsGoing: friendsGoing,
    );
  }

  ScheduleSummaryModel mapScheduleSummaryDto(EventSummaryDTO dto) {
    return ScheduleSummaryModel(
      items: dto.items.map(mapScheduleSummaryItemDto).toList(),
    );
  }

  ScheduleSummaryItemModel mapScheduleSummaryItemDto(EventSummaryItemDTO dto) {
    return ScheduleSummaryItemModel(
      dateTimeStart: DateTime.parse(dto.dateTimeStart),
      color: dto.color,
    );
  }

  // Invite status mapping is provided by InviteStatusDtoMapper.
}
