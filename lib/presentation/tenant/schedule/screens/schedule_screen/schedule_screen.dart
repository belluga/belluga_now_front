import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/controllers/schedule_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/widgets/dates_row.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_card.dart';
import 'package:belluga_now/presentation/view_models/event_card_data.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _controller = GetIt.I.get<ScheduleScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        automaticallyImplyLeading: false,
        title: const MainLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
            tooltip: 'Notificacoes',
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 1),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceDim,
                  child: const DateRow(),
                ),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamValueBuilder<List<EventModel>?>(
                  streamValue: _controller.eventsStreamValue,
                  onNullWidget: const Center(child: CircularProgressIndicator()),
                  builder: (context, events) {
                    final data = events ?? const <EventModel>[];
                    if (data.isEmpty) {
                      return const Center(
                        child: Text('Nenhum evento nesta data.'),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          for (final event in data) ...[
                            UpcomingEventCard(
                              data: _mapToViewModel(event),
                              onTap: () => _openEventDetail(event),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  EventCardData _mapToViewModel(EventModel event) {
    final imageUrl = event.thumb?.thumbUri.value.toString() ??
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800';
    final location = event.location.value;
    final participants = event.artists
        .map(
          (artist) => EventParticipantData(
            name: artist.name.value,
            isHighlight: artist.isHighlight.value,
          ),
        )
        .toList();
    final startDate = event.dateTimeStart.value ?? DateTime.now();
    final slug = _slugify(event.title.value);

    return EventCardData(
      slug: slug,
      title: event.title.value,
      imageUrl: imageUrl,
      startDateTime: startDate,
      venue: location,
      participants: participants,
    );
  }

  void _navigateToSearch() => context.router.push(const EventSearchRoute());

  void _openEventDetail(EventModel event) {
    final slug = _slugify(event.title.value);
    context.router.push(EventDetailRoute(slug: slug));
  }

  String _slugify(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
