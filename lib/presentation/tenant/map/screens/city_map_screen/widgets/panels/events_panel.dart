import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/map/direction_info.dart';
import 'package:belluga_now/domain/map/ride_share_provider.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/events_panel_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/panels/map_lateral_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
          final items = events;
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
                  ? DateFormat('dd/MM HH:mm').format(start)
                  : 'Horario a definir';
              return ListTile(
                title: Text(event.title.value),
                subtitle: Text('${event.location.value} - $formattedDate'),
                trailing: PopupMenuButton<_EventMenuAction>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) async =>
                      _handleAction(context, action, event),
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

  Future<void> _handleAction(
    BuildContext context,
    _EventMenuAction action,
    EventModel event,
  ) async {
    switch (action) {
      case _EventMenuAction.share:
        final payload = controller.buildSharePayload(event);
        await SharePlus.instance.share(
          ShareParams(text: payload.message, subject: payload.subject),
        );
        break;
      case _EventMenuAction.route:
        final info = await controller.prepareDirections(event);
        if (!context.mounted) {
          return;
        }
        if (info == null) {
          _showSnackbar(
              context, 'Este evento nao possui localizacao cadastrada.');
          return;
        }
        await _presentDirectionsOptions(context, info);
        break;
    }
  }

  Future<void> _presentDirectionsOptions(
    BuildContext context,
    DirectionsInfo info,
  ) async {
    final maps = info.availableMaps;
    final rideOptions = info.rideShareOptions;
    final totalOptions = maps.length + rideOptions.length;

    if (totalOptions == 0) {
      await _launchFallbackDirections(context, info);
      return;
    }

    if (totalOptions == 1) {
      if (maps.length == 1) {
        await maps.first.showDirections(
          destination: info.destination,
          destinationTitle: info.destinationName,
        );
      } else {
        final success = await controller.launchRideShareOption(
          rideOptions.first,
        );
        if (!success) {
          if (!context.mounted) {
            return;
          }
          await _launchFallbackDirections(context, info);
        }
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Escolha como chegar',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              for (final map in maps)
                ListTile(
                  leading: SvgPicture.asset(
                    map.icon,
                    width: 32,
                    height: 32,
                  ),
                  title: Text(map.mapName),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await map.showDirections(
                      destination: info.destination,
                      destinationTitle: info.destinationName,
                    );
                  },
                ),
              if (maps.isNotEmpty && rideOptions.isNotEmpty)
                const Divider(height: 1),
              for (final option in rideOptions)
                ListTile(
                  leading: Icon(
                    _rideShareIcon(option.provider),
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(option.label),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final success =
                        await controller.launchRideShareOption(option);
                    if (!success) {
                      if (!context.mounted) {
                        return;
                      }
                      await _launchFallbackDirections(context, info);
                    }
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  IconData _rideShareIcon(RideShareProvider provider) {
    switch (provider) {
      case RideShareProvider.uber:
        return Icons.local_taxi;
      case RideShareProvider.ninetyNine:
        return Icons.local_taxi_outlined;
    }
  }

  Future<void> _launchFallbackDirections(
    BuildContext context,
    DirectionsInfo info,
  ) async {
    final launched = await launchUrl(
      info.fallbackUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      if (!context.mounted) {
        return;
      }
      _showSnackbar(context, 'Nao foi possivel abrir o mapa para direcoes.');
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

enum _EventMenuAction { share, route }
