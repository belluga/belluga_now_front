import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/widgets/back_button_belluga.dart';
import 'package:belluga_now/presentation/tenant/widgets/date_grouped_event_list.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class EventSearchScreen extends StatefulWidget {
  const EventSearchScreen({super.key});

  @override
  State<EventSearchScreen> createState() => _EventSearchScreenState();
}

class _EventSearchScreenState extends State<EventSearchScreen> {
  final _controller = GetIt.I.get<EventSearchScreenController>();

  static final Uri _defaultEventImage = Uri.parse(
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
  );

  @override
  void initState() {
    super.initState();
    _controller.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller.searchController,
          focusNode: _controller.focusNode,
          style: theme.textTheme.titleMedium,
          decoration: InputDecoration(
            hintText: 'Buscar eventos...',
            border: InputBorder.none,
            hintStyle: theme.textTheme.titleMedium?.copyWith(
              color:
                  colorScheme.onSurfaceVariant.withAlpha((0.6 * 255).floor()),
            ),
          ),
          onChanged: _controller.searchEvents,
        ),
        automaticallyImplyLeading: false,
        leading: const BackButtonBelluga(),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          StreamValueBuilder<bool>(
            streamValue: _controller.showHistoryStreamValue,
            builder: (context, showHistory) {
              final isSelected = showHistory;
              return IconButton(
                onPressed: _controller.toggleHistory,
                tooltip: isSelected
                    ? 'Ocultar eventos já finalizados'
                    : 'Mostrar eventos já finalizados',
                icon: Icon(
                  Icons.history,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StreamValueBuilder<List<EventModel>?>(
          streamValue: _controller.searchResultsStreamValue,
          onNullWidget: const Center(
            child: CircularProgressIndicator(),
          ),
          builder: (context, events) {
            final data = events ?? [];

            if (data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: colorScheme.onSurfaceVariant
                          .withAlpha((0.5 * 255).floor()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum resultado encontrado',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Convert EventModel to VenueEventResume
            final resumes = data
                .map((e) => VenueEventResume.fromScheduleEvent(
                      e,
                      _defaultEventImage,
                    ))
                .toList();

            return DateGroupedEventList(
              events: resumes,
              onEventSelected: (slug) {
                context.router.push(ImmersiveEventDetailRoute(eventSlug: slug));
              },
            );
          },
        ),
      ),
    );
  }
}
