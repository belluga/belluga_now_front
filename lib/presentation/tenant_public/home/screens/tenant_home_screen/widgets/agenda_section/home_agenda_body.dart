import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/date_grouped_event_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class HomeAgendaBody extends StatefulWidget {
  const HomeAgendaBody({
    super.key,
    required this.controller,
  });

  final TenantHomeAgendaController controller;

  @override
  State<HomeAgendaBody> createState() => _HomeAgendaBodyState();
}

class _HomeAgendaBodyState extends State<HomeAgendaBody> {
  bool _agendaLoadScheduled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = widget.controller;

    return StreamValueBuilder<bool>(
      streamValue: controller.isInitialLoadingStreamValue,
      builder: (context, isInitialLoading) {
        final hasActiveFilters =
            controller.inviteFilterStreamValue.value != InviteFilter.none ||
                controller.showHistoryStreamValue.value;
        return StreamValueBuilder<List<EventModel>?>(
          streamValue: controller.displayedEventsStreamValue,
          onNullWidget: _buildFirstFetchLoading(
            theme: theme,
            colorScheme: colorScheme,
            controller: controller,
          ),
          builder: (context, events) {
            final resumes = events!
                .map(
                  (event) => VenueEventResume.fromScheduleEvent(
                    event,
                    ThumbUriValue(
                      defaultValue: controller.defaultEventImageUri,
                      isRequired: true,
                    )..parse(controller.defaultEventImageUri.toString()),
                  ),
                )
                .toList();
            return StreamValueBuilder<bool>(
              streamValue: controller.isPageLoadingStreamValue,
              builder: (context, isPageLoading) {
                if (isInitialLoading && resumes.isEmpty) {
                  return Center(
                    child: StreamValueBuilder<String>(
                      streamValue: controller.initialLoadingLabelStreamValue,
                      builder: (context, loadingLabel) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              loadingLabel.isEmpty
                                  ? 'Carregando agenda...'
                                  : loadingLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }

                if (resumes.isEmpty) {
                  if (isPageLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Buscando eventos perto de você...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final emptyLabel = hasActiveFilters
                      ? 'Nenhum resultado encontrado'
                      : 'Nenhum evento disponível no momento';
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
                  streamValue: controller.showHistoryStreamValue,
                  builder: (context, showHistory) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) =>
                          _handleAgendaScroll(notification, controller),
                      child: DateGroupedEventList(
                        primary: true,
                        events: resumes,
                        isConfirmed: (event) =>
                            controller.isEventConfirmed(event.id),
                        pendingInvitesCount: (event) =>
                            controller.pendingInviteCount(event.id),
                        distanceLabel: controller.distanceLabelFor,
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
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  bool _handleAgendaScroll(
    ScrollNotification notification,
    TenantHomeAgendaController controller,
  ) {
    final isUserDriven = switch (notification) {
      ScrollUpdateNotification update => update.dragDetails != null,
      ScrollEndNotification _ => true,
      OverscrollNotification _ => true,
      UserScrollNotification _ => true,
      _ => false,
    };
    if (!isUserDriven) return false;

    final isLoading = controller.isPageLoadingStreamValue.value ||
        controller.isInitialLoadingStreamValue.value;
    final hasMore = controller.hasMoreStreamValue.value;
    if (isLoading || !hasMore) return false;
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.metrics.pixels <= 0) return false;
    if (notification.metrics.extentAfter < 320) {
      if (_agendaLoadScheduled) return false;
      _agendaLoadScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _agendaLoadScheduled = false;
        controller.loadNextPage();
      });
    }
    return false;
  }

  Widget _buildFirstFetchLoading({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required TenantHomeAgendaController controller,
  }) {
    return Center(
      child: StreamValueBuilder<String>(
        streamValue: controller.initialLoadingLabelStreamValue,
        builder: (context, loadingLabel) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                loadingLabel.isEmpty
                    ? 'Buscando eventos perto de você...'
                    : loadingLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
