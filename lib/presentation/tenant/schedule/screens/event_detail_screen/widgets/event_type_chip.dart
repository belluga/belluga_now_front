import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:flutter/material.dart';

class EventTypeChip extends StatelessWidget {
  const EventTypeChip({super.key, required this.type});

  final EventTypeModel type;

  @override
  Widget build(BuildContext context) {
    final color = type.color.value;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: color.withValues(alpha: 0.16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          type.name.value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
