import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/date_grouped_event_list.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class EventSearchScreen extends StatefulWidget {
  const EventSearchScreen({
    super.key,
    this.startSearchActive = false,
    this.inviteFilter = InviteFilter.none,
  });

  final bool startSearchActive;
  final InviteFilter inviteFilter;

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
        child: StreamValueBuilder<List<EventModel>?>(
          streamValue: _controller.searchResultsStreamValue,
          onNullWidget: const Center(
            child: CircularProgressIndicator(),
          ),
          builder: (context, events) {
            final data = events ?? [];
            final showHistory = _controller.showHistoryStreamValue.value;

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

            final resumes = data
                .map((e) => VenueEventResume.fromScheduleEvent(
                      e,
                      _defaultEventImage,
                    ))
                .toList();

            return DateGroupedEventList(
              events: resumes,
              isConfirmed: (event) => _controller.isEventConfirmed(event.id),
              hasPendingInvite: (event) =>
                  _controller.hasPendingInvite(event.id),
              statusIconSize: 22,
              highlightNowEvents: true,
              highlightTodayEvents: true,
              sortDescending: showHistory,
              onEventSelected: (slug) {
                context.router.push(ImmersiveEventDetailRoute(eventSlug: slug));
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
          Icons.rocket_launch_outlined,
          color: theme.iconTheme.color,
          size: 22,
        );
      case InviteFilter.invitesAndConfirmed:
        return const Icon(
          Icons.rocket_launch_outlined,
          color: Colors.orange,
          size: 22,
        );
      case InviteFilter.confirmedOnly:
        return Icon(
          Icons.rocket_launch,
          color: theme.colorScheme.primary,
          size: 22,
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

  Icon _historyIcon(ThemeData theme, bool isSelected) {
    return Icon(
      isSelected ? Icons.history_toggle_off : Icons.history,
      color:
          isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
    );
  }
}
