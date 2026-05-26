import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/models/tenant_home_agenda_display_state.dart';
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
  static const double _paginationThreshold = 320.0;

  bool _agendaLoadScheduled = false;
  _AgendaScrollSnapshot? _currentScrollSnapshot;
  _AgendaScrollSnapshot? _lastUserScrollSnapshot;
  StreamSubscription<bool>? _initialLoadingSubscription;
  StreamSubscription<bool>? _pageLoadingSubscription;

  @override
  void initState() {
    super.initState();
    _attachLoadingListeners(widget.controller);
  }

  @override
  void didUpdateWidget(covariant HomeAgendaBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _detachLoadingListeners();
      _lastUserScrollSnapshot = null;
      _agendaLoadScheduled = false;
      _attachLoadingListeners(widget.controller);
    }
  }

  @override
  void dispose() {
    _detachLoadingListeners();
    super.dispose();
  }

  void _attachLoadingListeners(TenantHomeAgendaController controller) {
    _initialLoadingSubscription =
        controller.isInitialLoadingStreamValue.stream.listen((_) {
      _replayPendingBottomScrollIfReady(controller);
    });
    _pageLoadingSubscription =
        controller.isPageLoadingStreamValue.stream.listen((_) {
      _replayPendingBottomScrollIfReady(controller);
    });
  }

  void _detachLoadingListeners() {
    _initialLoadingSubscription?.cancel();
    _initialLoadingSubscription = null;
    _pageLoadingSubscription?.cancel();
    _pageLoadingSubscription = null;
  }

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
                controller.showHistoryStreamValue.value ||
                controller.discoveryFilterSelectionStreamValue.value.isNotEmpty;
        return StreamValueBuilder<TenantHomeAgendaDisplayState?>(
          streamValue: controller.displayStateStreamValue,
          onNullWidget: _buildFirstFetchLoading(
            theme: theme,
            colorScheme: colorScheme,
            controller: controller,
          ),
          builder: (context, displayState) {
            final resumes = displayState!.events
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
                    return NotificationListener<ScrollMetricsNotification>(
                      onNotification: _handleAgendaMetricsChanged,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) =>
                            _handleAgendaScroll(notification, controller),
                        child: DateGroupedEventList(
                          primary: true,
                          events: resumes,
                          isConfirmed: (event) =>
                              controller.isOccurrenceConfirmed(
                            event.selectedOccurrenceId ?? '',
                          ),
                          pendingInvitesCount: (event) =>
                              controller.pendingInviteCount(
                            event.selectedOccurrenceId ?? '',
                          ),
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
                          onEventSelected: (event) {
                            context.router.push(
                              ImmersiveEventDetailRoute(
                                eventSlug: event.slug,
                                occurrenceId: event.selectedOccurrenceId,
                              ),
                            );
                          },
                        ),
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
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    _currentScrollSnapshot = _snapshotFromMetrics(notification.metrics);

    controller.updateRadiusActionCompactStateFromScroll(
      notification.metrics.pixels,
    );

    final isUserDriven = switch (notification) {
      ScrollUpdateNotification update => update.dragDetails != null,
      ScrollEndNotification _ => true,
      OverscrollNotification _ => true,
      UserScrollNotification _ => true,
      _ => false,
    };
    if (!isUserDriven) return false;

    _lastUserScrollSnapshot = _AgendaScrollSnapshot(
      pixels: notification.metrics.pixels,
      extentAfter: notification.metrics.extentAfter,
    );

    final isLoading = controller.isPageLoadingStreamValue.value ||
        controller.isInitialLoadingStreamValue.value;
    final hasMore = controller.hasMoreStreamValue.value;
    if (isLoading || !hasMore) return false;
    _scheduleNextPageIfNearBottom(
      controller,
      pixels: notification.metrics.pixels,
      extentAfter: notification.metrics.extentAfter,
    );
    return false;
  }

  void _replayPendingBottomScrollIfReady(
    TenantHomeAgendaController controller,
  ) {
    if (!mounted ||
        controller.isInitialLoadingStreamValue.value ||
        controller.isPageLoadingStreamValue.value ||
        !controller.hasMoreStreamValue.value) {
      return;
    }

    if (_lastUserScrollSnapshot == null) {
      return;
    }

    final currentSnapshot = _currentScrollSnapshot;
    if (currentSnapshot == null ||
        !_isNearBottom(
          pixels: currentSnapshot.pixels,
          extentAfter: currentSnapshot.extentAfter,
        )) {
      _lastUserScrollSnapshot = null;
      return;
    }

    _scheduleNextPageIfNearBottom(
      controller,
      pixels: currentSnapshot.pixels,
      extentAfter: currentSnapshot.extentAfter,
    );
  }

  void _scheduleNextPageIfNearBottom(
    TenantHomeAgendaController controller, {
    required double pixels,
    required double extentAfter,
  }) {
    if (!_isNearBottom(pixels: pixels, extentAfter: extentAfter)) {
      return;
    }
    if (_agendaLoadScheduled) {
      return;
    }
    _lastUserScrollSnapshot = null;
    _agendaLoadScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _agendaLoadScheduled = false;
      if (!mounted) {
        return;
      }
      controller.loadNextPage();
    });
  }

  bool _handleAgendaMetricsChanged(ScrollMetricsNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    _currentScrollSnapshot = _snapshotFromMetrics(notification.metrics);
    return false;
  }

  _AgendaScrollSnapshot _snapshotFromMetrics(ScrollMetrics metrics) {
    return _AgendaScrollSnapshot(
      pixels: metrics.pixels,
      extentAfter: metrics.extentAfter,
    );
  }

  bool _isNearBottom({
    required double pixels,
    required double extentAfter,
  }) {
    return pixels > 0 && extentAfter < _paginationThreshold;
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

class _AgendaScrollSnapshot {
  const _AgendaScrollSnapshot({
    required this.pixels,
    required this.extentAfter,
  });

  final double pixels;
  final double extentAfter;
}
