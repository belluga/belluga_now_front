import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:flutter/material.dart';

class EventActionUnsupportedNavigation extends EventActionModel {
  EventActionUnsupportedNavigation({
    required super.id,
    required super.label,
    required super.color,
    this.message,
  });

  final String? message;

  @override
  void open(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          message ??
              'Em breve você poderá acessar esta experiência diretamente pelo app.',
        ),
      ),
    );
  }
}
