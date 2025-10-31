import 'package:belluga_now/domain/schedule/event_action_item_types.dart';
import 'package:belluga_now/domain/schedule/event_action_model/event_action_in_app_navigation.dart';
import 'package:flutter/material.dart';

class EventActionCourseNavigation extends EventActionInAppNavigation {
  EventActionCourseNavigation({
    required super.id,
    required super.label,
    required super.color,
    required super.itemId,
    required super.itemType,
  }) : assert(itemType.value == EventActionItemTypes.courseItem,
            'EventActionCourseNavigation must be used with CourseItem type');

  @override
  void open(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Navegação para cursos ainda não disponível.'),
      ),
    );
  }
}
