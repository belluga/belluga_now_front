import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/tenant_public_safe_back.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/widgets/agenda_app_bar.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/date_grouped_event_list.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class EventSearchScreen extends StatefulWidget {
  const EventSearchScreen({
    super.key,
    this.inviteFilter = InviteFilter.none,
    this.startWithHistory = false,
  });

  final InviteFilter inviteFilter;
  final bool startWithHistory;

  @override
  State<EventSearchScreen> createState() => _EventSearchScreenState();
}

class _EventSearchScreenState extends State<EventSearchScreen> {
  final EventSearchScreenController _controller =
      GetIt.I.get<EventSearchScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init(startWithHistory: widget.startWithHistory);
    _controller.setInviteFilter(widget.inviteFilter);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleBack();
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight + topPadding),
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: AgendaAppBar(
              controller: _controller,
              onBack: _handleBack,
              actions: const AgendaAppBarActions(
                showBack: true,
                showSearch: false,
                showRadius: true,
                showInviteFilter: true,
                showHistory: true,
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: StreamValueBuilder<bool>(
            streamValue: _controller.isInitialLoadingStreamValue,
            builder: (context, isInitialLoading) {
              return StreamValueBuilder<List<VenueEventResume>>(
                streamValue: _controller.displayedEventsStreamValue,
                builder: (context, events) {
                  return StreamValueBuilder<bool>(
                    streamValue: _controller.isPageLoadingStreamValue,
                    builder: (context, isPageLoading) {
                      final hasInviteFilter =
                          _controller.inviteFilterStreamValue.value !=
                              InviteFilter.none;
                      final showHistory =
                          _controller.showHistoryStreamValue.value;
                      final hasActiveFilters = hasInviteFilter || showHistory;
                      final emptyLabel = hasActiveFilters
                          ? 'Nenhum resultado encontrado'
                          : 'Nenhum evento disponível no momento';

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
                                emptyLabel,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return StreamValueBuilder<bool>(
                        streamValue: _controller.showHistoryStreamValue,
                        builder: (context, showHistory) {
                          return PrimaryScrollController(
                            controller: _controller.scrollController,
                            child: DateGroupedEventList(
                              primary: true,
                              events: events,
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
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
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
                            ),
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
      ),
    );
  }

  // AgendaAppBar handles icons/tooltips and radius modal.

  void _handleBack() {
    performTenantPublicSafeBack(
      context.router,
      fallbackRoute: const ProfileRoute(),
    );
  }
}
