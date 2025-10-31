import 'package:belluga_now/domain/schedule/event_action_model/event_action_external_navigation.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_unsupported_navigation.dart';
import 'package:belluga_now/domain/schedule/event_action_types.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_actions_dto.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';
import 'package:flutter/material.dart';

abstract class EventActionModel {
  final MongoIDValue? id;
  final TitleValue label;
  final ColorValue? color;

  EventActionModel({
    required this.id,
    required this.label,
    required this.color,
  });

  static EventActionModel fromDTO(EventActionsDTO dto) {
    final MongoIDValue _id = MongoIDValue()..tryParse(dto.id);
    final TitleValue _label = TitleValue()..parse(dto.label);
    final ColorValue? colorValue = dto.color == null
        ? null
        : (ColorValue(defaultValue: const Color(0xFF000000))
          ..tryParse(dto.color!));

    final EventActionTypes _openIn = EventActionTypes.values.byName(dto.openIn);

    switch (_openIn) {
      case EventActionTypes.external:
        if (dto.externalUrl == null || dto.externalUrl!.isEmpty) {
          return EventActionUnsupportedNavigation(
            id: _id,
            label: _label,
            color: colorValue,
            message:
                'Link externo indisponível no momento. Tente novamente mais tarde.',
          );
        }
        return EventActionExternalNavigation(
          id: _id,
          label: _label,
          color: colorValue,
          externalUrl: URIValue()..tryParse(dto.externalUrl),
        );
      case EventActionTypes.inApp:
        return EventActionUnsupportedNavigation(
          id: _id,
          label: _label,
          color: colorValue,
          message:
              'Esta ação será habilitada quando a navegação in-app estiver disponível.',
        );
    }
  }

  void open(BuildContext context);
}
