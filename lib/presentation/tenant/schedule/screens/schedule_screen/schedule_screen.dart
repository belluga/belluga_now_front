import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/controllers/schedule_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/widgets/dates_row.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/upcoming_event_card.dart';
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
                child: StreamValueBuilder<List<VenueEventResume>?>(
                  streamValue: _controller.eventsStreamValue,
                  onNullWidget:
                      const Center(child: CircularProgressIndicator()),
                  builder: (context, events) {
                    final data = events ?? const <VenueEventResume>[];
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
                              event: event,
                              onTap: () => _openEventDetail(event.slug),
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

  void _navigateToSearch() => context.router.push(const EventSearchRoute());

  void _openEventDetail(String slug) {
    context.router.push(EventDetailRoute(slug: slug));
  }
}
