import 'package:belluga_now/domain/schedule/event_action_model/event_action_model.dart';
import 'package:flutter/material.dart';

class EventActionButton extends StatefulWidget {
  final EventActionModel eventAction;

  const EventActionButton({super.key, required this.eventAction});

  @override
  State<EventActionButton> createState() => _EventActionButtonState();
}

class _EventActionButtonState extends State<EventActionButton> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor =
        widget.eventAction.color?.value ?? colorScheme.secondary;
    final textColor =
        ThemeData.estimateBrightnessForColor(buttonColor) == Brightness.dark
            ? colorScheme.onPrimary
            : colorScheme.onSecondary;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        backgroundColor: buttonColor,
        foregroundColor: textColor,
      ),
      onPressed: _open,
      child: Text(widget.eventAction.label.value),
    );
  }

  void _open() => widget.eventAction.open(context);
}
