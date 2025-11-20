import 'package:belluga_now/domain/schedule/event_action_model/event_action_external_navigation.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_unsupported_navigation.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/schedule/dtos/event_action_dto.dart';
import 'package:flutter/material.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

abstract class EventActionModel {
  final MongoIDValue? id;
  final TitleValue label;
  final ColorValue? color;

  EventActionModel({
    required this.id,
    required this.label,
    required this.color,
  });

  void open(BuildContext context);

  static EventActionModel fromDto(EventActionDto dto) {
    final idValue = dto.id != null ? (MongoIDValue()..parse(dto.id!)) : null;
    final labelValue = TitleValue()..parse(dto.label);
    final colorValue = dto.color != null
        ? (ColorValue(defaultValue: const Color(0xFF000000))..parse(dto.color!))
        : null;

    if (dto.type == 'external_navigation') {
      return EventActionExternalNavigation(
        id: idValue,
        label: labelValue,
        color: colorValue,
        externalUrl: URIValue()..parse(dto.externalUrl ?? ''),
      );
    } else {
      return EventActionUnsupportedNavigation(
        id: idValue,
        label: labelValue,
        color: colorValue,
        message: dto.message,
      );
    }
  }
}
