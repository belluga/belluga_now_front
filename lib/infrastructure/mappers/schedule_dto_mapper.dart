import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/courses/value_objects/slug_value.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_external_navigation.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_unsupported_navigation.dart';
import 'package:belluga_now/domain/schedule/event_action_types.dart';
import 'package:belluga_now/domain/schedule/event_artist_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_item_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_artist_is_highlight_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_artist_name_value.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/mappers/course_dto_mapper.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_actions_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_artist_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_summary_item_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_type_dto.dart';
import 'package:flutter/material.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

mixin ScheduleDtoMapper on CourseDtoMapper {
  EventModel mapEvent(EventDTO dto) {
    return EventModel(
      id: MongoIDValue()..tryParse(dto.id),
      type: mapEventType(dto.type),
      title: TitleValue()..parse(dto.title),
      content: HTMLContentValue()..parse(dto.content),
      location: DescriptionValue()..parse(dto.location),
      thumb: dto.thumb != null ? mapThumb(dto.thumb!) : null,
      dateTimeStart: DateTimeValue()..parse(dto.dateTimeStart),
      dateTimeEnd: dto.dateTimeEnd != null
          ? (DateTimeValue()..parse(dto.dateTimeEnd!))
          : null,
      artists: dto.artists.map(mapEventArtist).toList(),
      actions: dto.actions.map(mapEventAction).toList(),
      coordinate: (dto.latitude != null && dto.longitude != null)
          ? CityCoordinate(
              latitude: dto.latitude!,
              longitude: dto.longitude!,
            )
          : null,
    );
  }

  EventTypeModel mapEventType(EventTypeDTO dto) {
    return EventTypeModel(
      id: MongoIDValue()..tryParse(dto.id),
      name: TitleValue(minLenght: 1)..parse(dto.name),
      slug: SlugValue()..parse(dto.slug),
      description: DescriptionValue()..parse(dto.description),
      icon: SlugValue()..tryParse(dto.icon),
      color: ColorValue(defaultValue: const Color(0xFF4FA0E3))
        ..tryParse(dto.color ?? '#FF4FA0E3'),
    );
  }

  EventArtistModel mapEventArtist(EventArtistDTO dto) {
    final name = EventArtistNameValue()..parse(dto.name);
    final avatar = URIValue(
      defaultValue: Uri.parse(
        'https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308',
      ),
    )..tryParse(dto.avatarUrl);

    return EventArtistModel(
      name: name,
      avatarUrl: avatar,
      isHighlight: EventArtistIsHighlightValue()
        ..parse((dto.highlight ?? false).toString()),
    );
  }

  EventActionModel mapEventAction(EventActionsDTO dto) {
    final id = MongoIDValue()..tryParse(dto.id);
    final label = TitleValue()..parse(dto.label);
    final ColorValue? colorValue;
    if (dto.color == null) {
      colorValue = null;
    } else {
      colorValue = ColorValue(defaultValue: const Color(0xFF000000))
        ..tryParse(dto.color!);
    }

    final openIn = EventActionTypes.values.byName(dto.openIn);

    switch (openIn) {
      case EventActionTypes.external:
        if (dto.externalUrl == null || dto.externalUrl!.isEmpty) {
          return EventActionUnsupportedNavigation(
            id: id,
            label: label,
            color: colorValue,
            message:
                'Link externo indisponível no momento. Tente novamente mais tarde.',
          );
        }
        return EventActionExternalNavigation(
          id: id,
          label: label,
          color: colorValue,
          externalUrl: URIValue()..tryParse(dto.externalUrl!),
        );
      case EventActionTypes.inApp:
        return EventActionUnsupportedNavigation(
          id: id,
          label: label,
          color: colorValue,
          message:
              'Esta ação será habilitada quando a navegação in-app estiver disponível.',
        );
    }
  }

  ScheduleSummaryModel mapScheduleSummary(EventSummaryDTO dto) {
    return ScheduleSummaryModel(
      items: dto.items.map(mapScheduleSummaryItem).toList(),
    );
  }

  ScheduleSummaryItemModel mapScheduleSummaryItem(EventSummaryItemDTO dto) {
    return ScheduleSummaryItemModel(
      color: dto.color,
      dateTimeStart: DateTime.parse(dto.dateTimeStart),
    );
  }
}
