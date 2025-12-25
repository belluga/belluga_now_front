import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant/schedule/widgets/agenda_app_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/date_grouped_event_list.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class EventSearchScreen extends StatefulWidget {
  const EventSearchScreen({
    super.key,
    this.startSearchActive = false,
    this.initialSearchQuery,
    this.inviteFilter = InviteFilter.none,
    this.startWithHistory = false,
  });

  final bool startSearchActive;
  final String? initialSearchQuery;
  final InviteFilter inviteFilter;
  final bool startWithHistory;

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
    _controller.init(startWithHistory: widget.startWithHistory);
    _controller.setInitialSearchQuery(widget.initialSearchQuery);
    _controller.setSearchActive(widget.startSearchActive);
    _controller.setInviteFilter(widget.inviteFilter);
  }

  @override
  void dispose() {
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AgendaAppBar(
          searchActiveStreamValue: _controller.searchActiveStreamValue,
          searchController: _controller.searchController,
          focusNode: _controller.focusNode,
          onToggleSearchMode: _controller.toggleSearchMode,
          onSearchChanged: _controller.searchEvents,
          maxRadiusMetersStreamValue: _controller.maxRadiusMetersStreamValue,
          radiusMetersStreamValue: _controller.radiusMetersStreamValue,
          onSetRadiusMeters: _controller.setRadiusMeters,
          inviteFilterStreamValue: _controller.inviteFilterStreamValue,
          onCycleInviteFilter: _controller.cycleInviteFilter,
          showHistoryStreamValue: _controller.showHistoryStreamValue,
          onToggleHistory: _controller.toggleHistory,
        ),
      ),
      body: SafeArea(
        top: false,
        child: StreamValueBuilder<bool>(
          streamValue: _controller.isInitialLoadingStreamValue,
          builder: (context, isInitialLoading) {
            return StreamValueBuilder<List<EventModel>>(
              streamValue: _controller.displayedEventsStreamValue,
              builder: (context, events) {
                return StreamValueBuilder<bool>(
                  streamValue: _controller.isPageLoadingStreamValue,
                  builder: (context, isPageLoading) {
                    if (isInitialLoading && events.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (events.isEmpty) {
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

                    final resumes = events
                        .map((e) => VenueEventResume.fromScheduleEvent(
                              e,
                              _defaultEventImage,
                            ))
                        .toList();

                    return StreamValueBuilder<bool>(
                      streamValue: _controller.showHistoryStreamValue,
                      builder: (context, showHistory) {
                        return DateGroupedEventList(
                          controller: _controller.scrollController,
                          events: resumes,
                          isConfirmed: (event) =>
                              _controller.isEventConfirmed(event.id),
                          pendingInvitesCount: (event) =>
                              _controller.pendingInviteCount(event.id),
                          distanceLabel: _controller.distanceLabelFor,
                          statusIconSize: 22,
                          highlightNowEvents: true,
                          highlightTodayEvents: true,
                          sortDescending: showHistory,
                          footer: isPageLoading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              : null,
                          onEventSelected: (slug) {
                            context.router.push(
                              ImmersiveEventDetailRoute(eventSlug: slug),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 1),
    );
  }

  // AgendaAppBar handles icons/tooltips and radius modal.
}
