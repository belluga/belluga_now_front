import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/date_grouped_event_list.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class EventSearchScreen extends StatefulWidget {
  const EventSearchScreen({
    super.key,
    this.startSearchActive = false,
    this.inviteFilter = InviteFilter.none,
    this.startWithHistory = false,
  });

  final bool startSearchActive;
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
    _controller.setSearchActive(widget.startSearchActive);
    _controller.setInviteFilter(widget.inviteFilter);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: StreamValueBuilder<bool>(
          streamValue: _controller.searchActiveStreamValue,
          builder: (context, isActive) {
            return AppBar(
              automaticallyImplyLeading: false,
              leading: null,
              leadingWidth: 0,
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isActive
                    ? TextField(
                        key: const ValueKey('searchField'),
                        controller: _controller.searchController,
                        focusNode: _controller.focusNode,
                        style: theme.textTheme.titleMedium,
                        decoration: InputDecoration(
                          hintText: 'Buscar eventos...',
                          border: InputBorder.none,
                          hintStyle: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withAlpha((0.6 * 255).floor()),
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Fechar busca',
                            onPressed: _controller.toggleSearchMode,
                            icon: Icon(
                              Icons.close,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        onChanged: _controller.searchEvents,
                        autofocus: true,
                      )
                    : Text(
                        'Agenda',
                        key: const ValueKey('searchLabel'),
                        style: theme.textTheme.titleLarge,
                      ),
              ),
              actionsPadding: const EdgeInsets.only(right: 8),
              actions: [
                if (!isActive)
                  IconButton(
                    tooltip: 'Buscar eventos',
                    onPressed: _controller.toggleSearchMode,
                    icon: Icon(
                      Icons.search,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                StreamValueBuilder<InviteFilter>(
                  streamValue: _controller.inviteFilterStreamValue,
                  builder: (context, filter) {
                    final theme = Theme.of(context);
                    return IconButton(
                      tooltip: _inviteFilterTooltip(filter),
                      onPressed: _controller.cycleInviteFilter,
                      icon: _inviteFilterIcon(theme, filter),
                    );
                  },
                ),
                StreamValueBuilder<bool>(
                  streamValue: _controller.showHistoryStreamValue,
                  builder: (context, showHistory) {
                    final isSelected = showHistory;
                    return IconButton(
                      onPressed: _controller.toggleHistory,
                      tooltip: isSelected
                          ? 'Ver futuros e em andamento'
                          : 'Ver eventos passados',
                      icon: _historyIcon(theme, isSelected),
                    );
                  },
                ),
              ],
            );
          },
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

  Icon _inviteFilterIcon(ThemeData theme, InviteFilter filter) {
    switch (filter) {
      case InviteFilter.none:
        return Icon(
          BooraIcons.invite_outlined,
          color: theme.iconTheme.color,
          size: 20,
        );
      case InviteFilter.invitesAndConfirmed:
        return Icon(
          BooraIcons.invite_outlined,
          color: theme.colorScheme.tertiary,
          size: 20,
        );
      case InviteFilter.confirmedOnly:
        return Icon(
          BooraIcons.invite_solid,
          color: theme.colorScheme.primary,
          size: 20,
        );
    }
  }

  String _inviteFilterTooltip(InviteFilter filter) {
    switch (filter) {
      case InviteFilter.none:
        return 'Todos os eventos';
      case InviteFilter.invitesAndConfirmed:
        return 'Convites pendentes e confirmados';
      case InviteFilter.confirmedOnly:
        return 'Somente confirmados';
    }
  }

  Widget _historyIcon(ThemeData theme, bool isSelected) {
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final icon = isSelected ? Icons.history : Icons.history_outlined;

    return Icon(icon, color: color, size: 22);
  }
}
