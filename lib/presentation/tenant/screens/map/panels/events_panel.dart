import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/events_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/panels/map_lateral_panel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class EventsPanel extends StatelessWidget {
  const EventsPanel({
    super.key,
    required this.controller,
    required this.onClose,
    required this.title,
    required this.icon,
  });

  final EventsPanelController controller;
  final VoidCallback onClose;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MapLateralPanel(
      title: title,
      icon: icon,
      onClose: onClose,
      child: StreamValueBuilder<List<EventModel>>(
        streamValue: controller.events,
        builder: (_, events) {
          final items = events ?? const <EventModel>[];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Nenhum evento disponivel no momento.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final event = items[index];
              final start = event.dateTimeStart.value;
              final formattedDate = start != null
                  ? DateFormat('dd/MM • HH:mm').format(start)
                  : 'Horario a definir';
              return ListTile(
                title: Text(event.title.value),
                subtitle: Text('${event.location.value} • $formattedDate'),
                trailing: PopupMenuButton<_EventMenuAction>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) => _handleAction(context, action, event),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _EventMenuAction.share,
                      child: Text('Compartilhar'),
                    ),
                    if (event.coordinate != null)
                      const PopupMenuItem(
                        value: _EventMenuAction.route,
                        child: Text('Tracar rota'),
                      ),
                  ],
                ),
                onTap: () => controller.selectEvent(event),
              );
            },
          );
        },
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    _EventMenuAction action,
    EventModel event,
  ) {
    switch (action) {
      case _EventMenuAction.share:
        controller.shareEvent(event);
        break;
      case _EventMenuAction.route:
        controller.routeToEvent(event, context);
        break;
    }
  }
}

enum _EventMenuAction { share, route }
