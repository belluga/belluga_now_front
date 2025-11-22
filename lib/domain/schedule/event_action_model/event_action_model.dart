import 'package:belluga_now/domain/schedule/event_action_model/event_action_external_navigation.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_unsupported_navigation.dart';
import 'package:belluga_now/domain/schedule/event_action_types.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_action_dto.dart';
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

  static EventActionModel fromDto(EventActionDTO dto) {
    final idValue = dto.id != null ? (MongoIDValue()..parse(dto.id!)) : null;
    final labelValue = TitleValue()..parse(dto.label);
    final colorValue = dto.color != null
        ? (ColorValue(defaultValue: const Color(0xFF000000))..parse(dto.color!))
        : null;

    final openIn = EventActionTypes.values
        .firstWhere((value) => value.name == dto.openIn, orElse: () {
      return EventActionTypes.external;
    });

    switch (openIn) {
      case EventActionTypes.external:
        if (dto.externalUrl == null || dto.externalUrl!.isEmpty) {
          return EventActionUnsupportedNavigation(
            id: idValue,
            label: labelValue,
            color: colorValue,
            message: dto.message ??
                'Link externo indisponível no momento. Tente novamente mais tarde.',
          );
        }
        return EventActionExternalNavigation(
          id: idValue,
          label: labelValue,
          color: colorValue,
          externalUrl: URIValue()..parse(dto.externalUrl ?? ''),
        );
      case EventActionTypes.inApp:
        return EventActionUnsupportedNavigation(
          id: idValue,
          label: labelValue,
          color: colorValue,
          message: dto.message ??
              'Esta ação será habilitada quando a navegação in-app estiver disponível.',
        );
    }
  }
}
