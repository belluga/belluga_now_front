import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/extensions/event_data_formating.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/widgets/favorite_section/favorites_section_builder.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/controllers/event_search_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:belluga_now/presentation/tenant/widgets/carousel_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/date_grouped_event_list.dart';
import 'package:belluga_now/presentation/tenant/widgets/event_info_row.dart';
import 'package:belluga_now/presentation/tenant/widgets/invite_status_icon.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

const Duration _assumedEventDuration = Duration(hours: 3);

class TenantHomeProvisionalScreen extends StatefulWidget {
  const TenantHomeProvisionalScreen({super.key});

  @override
  State<TenantHomeProvisionalScreen> createState() =>
      _TenantHomeProvisionalScreenState();
}

class _TenantHomeProvisionalScreenState
    extends State<TenantHomeProvisionalScreen> {
  static final Uri _defaultEventImage = Uri.parse(
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
  );

  final TenantHomeController _homeController =
      GetIt.I.get<TenantHomeController>();
  final EventSearchScreenController _agendaController =
      GetIt.I.get<EventSearchScreenController>();

  @override
  void initState() {
    super.initState();
    _homeController.init();
    _agendaController.init(startWithHistory: false);
    _agendaController.setInviteFilter(InviteFilter.none);
    _agendaController.setSearchActive(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 0),
      body: SafeArea(
        top: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildHomeAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Seus Favoritos',
                      onPressed: () {},
                    ),
                    FavoritesSectionBuilder(controller: _homeController),
                    const SizedBox(height: 12),
                    _buildMyEventsCarousel(context),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                minHeight: kToolbarHeight,
                maxHeight: kToolbarHeight,
                child: _AgendaAppBar(controller: _agendaController),
              ),
            ),
          ],
          body: _buildAgendaBody(context),
        ),
      ),
    );
  }

  SliverAppBar _buildHomeAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MainLogo(),
                StreamValueBuilder<String?>(
                  streamValue: _homeController.userAddressStreamValue,
                  builder: (context, address) {
                    if (address == null || address.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            context.router.push(const CityMapRoute()),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
      ],
    );
  }

  Widget _buildMyEventsCarousel(BuildContext context) {
    return StreamValueBuilder<List<VenueEventResume>>(
      streamValue: _homeController.myEventsStreamValue,
      builder: (context, events) {
        final filtered = _filterConfirmedUpcoming(events);
        if (filtered.isEmpty) {
          return const SizedBox.shrink();
        }

        final cardWidth = MediaQuery.of(context).size.width * 0.8;
        final cardHeight = cardWidth * 9 / 16;
        return StreamValueBuilder<Set<String>>(
          streamValue: _homeController.confirmedIdsStream,
          builder: (context, confirmedIds) {
            return StreamValueBuilder<List<InviteModel>>(
              streamValue: _homeController.pendingInvitesStreamValue,
              builder: (context, pendingInvites) {
                final hasOverflow = filtered.length > 5;
                final displayItems = filtered.take(hasOverflow ? 4 : 5).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Meus Eventos',
                      onPressed: _openConfirmedAgenda,
                      onTitleTap: () => _openFirstMyEvent(filtered),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: SizedBox(
                        height: cardHeight,
                        child: CarouselView(
                          itemExtent: cardWidth,
                          itemSnapping: true,
                          enableSplash: false,
                          children: [
                            ...displayItems.map((event) {
                              final isConfirmed = confirmedIds.contains(event.id);
                              final pendingCount = pendingInvites
                                  .where((invite) =>
                                      invite.eventIdValue.value == event.id)
                                  .length;
                              return _MyEventsCarouselCard(
                                event: event,
                                isConfirmed: isConfirmed,
                                pendingInvitesCount: pendingCount,
                                distanceLabel:
                                    _homeController.distanceLabelFor(event),
                                onTap: () => _openEventDetailSlug(event.slug),
                              );
                            }),
                            if (hasOverflow)
                              _SeeMoreMyEventsCard(onTap: _openConfirmedAgenda),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAgendaBody(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamValueBuilder<bool>(
      streamValue: _agendaController.isInitialLoadingStreamValue,
      builder: (context, isInitialLoading) {
        return StreamValueBuilder<List<EventModel>>(
          streamValue: _agendaController.displayedEventsStreamValue,
          builder: (context, events) {
            return StreamValueBuilder<bool>(
              streamValue: _agendaController.isPageLoadingStreamValue,
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
                  streamValue: _agendaController.showHistoryStreamValue,
                  builder: (context, showHistory) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        final isLoading =
                            _agendaController.isPageLoadingStreamValue.value ||
                                _agendaController
                                    .isInitialLoadingStreamValue.value;
                        final hasMore =
                            _agendaController.hasMoreStreamValue.value;
                        if (isLoading || !hasMore) return false;
                        if (notification.metrics.extentAfter < 320) {
                          _agendaController.loadNextPage();
                        }
                        return false;
                      },
                      child: DateGroupedEventList(
                        events: resumes,
                        isConfirmed: (event) =>
                            _agendaController.isEventConfirmed(event.id),
                        pendingInvitesCount: (event) =>
                            _agendaController.pendingInviteCount(event.id),
                        distanceLabel: _agendaController.distanceLabelFor,
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

  List<VenueEventResume> _filterConfirmedUpcoming(
    List<VenueEventResume> events,
  ) {
    final now = DateTime.now();
    return events.where((event) {
      final start = event.startDateTime;
      if (!start.isAfter(now)) {
        final end = start.add(_assumedEventDuration);
        return now.isBefore(end);
      }
      return true;
    }).toList();
  }

  void _openConfirmedAgenda() {
    context.router.push(
      EventSearchRoute(inviteFilter: InviteFilter.confirmedOnly),
    );
  }

  void _openFirstMyEvent(List<VenueEventResume> events) {
    if (events.isEmpty) return;
    _openEventDetailSlug(events.first.slug);
  }

  void _openEventDetailSlug(String slug) {
    context.router.push(ImmersiveEventDetailRoute(eventSlug: slug));
  }
}

class _AgendaAppBar extends StatelessWidget {
  const _AgendaAppBar({required this.controller});

  final EventSearchScreenController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamValueBuilder<bool>(
      streamValue: controller.searchActiveStreamValue,
      builder: (context, isActive) {
        return AppBar(
          primary: false,
          toolbarHeight: kToolbarHeight,
          automaticallyImplyLeading: false,
          leading: null,
          leadingWidth: 0,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isActive
                ? TextField(
                    key: const ValueKey('searchField'),
                    controller: controller.searchController,
                    focusNode: controller.focusNode,
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
                        onPressed: controller.toggleSearchMode,
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    onChanged: controller.searchEvents,
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
                onPressed: controller.toggleSearchMode,
                icon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (!isActive)
              StreamValueBuilder<double>(
                streamValue: controller.maxRadiusMetersStreamValue,
                builder: (context, maxRadiusMeters) {
                  return StreamValueBuilder<double>(
                    streamValue: controller.radiusMetersStreamValue,
                    builder: (context, radiusMeters) {
                      return IconButton(
                        tooltip:
                            'Raio ${_formatRadiusLabel(radiusMeters)}',
                        onPressed: () => _showRadiusSelector(
                          context,
                          radiusMeters,
                          maxRadiusMeters,
                        ),
                        icon: Icon(
                          Icons.my_location_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  );
                },
              ),
            if (!isActive)
              StreamValueBuilder<InviteFilter>(
                streamValue: controller.inviteFilterStreamValue,
                builder: (context, filter) {
                  return IconButton(
                    tooltip: _inviteFilterTooltip(filter),
                    onPressed: controller.cycleInviteFilter,
                    icon: _inviteFilterIcon(theme, filter),
                  );
                },
              ),
            if (!isActive)
              StreamValueBuilder<bool>(
                streamValue: controller.showHistoryStreamValue,
                builder: (context, showHistory) {
                  final isSelected = showHistory;
                  return IconButton(
                    onPressed: controller.toggleHistory,
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

  static String _formatRadiusLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(0)} km';
  }

  Future<void> _showRadiusSelector(
    BuildContext context,
    double selectedMeters,
    double maxRadiusMeters,
  ) async {
    final theme = Theme.of(context);
    const minRadiusKm = 1.0;
    final maxKm = (maxRadiusMeters / 1000) < minRadiusKm
        ? minRadiusKm
        : (maxRadiusMeters / 1000);
    double currentKm = (selectedMeters / 1000).clamp(minRadiusKm, maxKm);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.my_location_outlined,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currentKm.toStringAsFixed(0)} km',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: currentKm,
                      min: minRadiusKm,
                      max: maxKm,
                      divisions: (maxKm - minRadiusKm).round().clamp(1, 200),
                      onChanged: (value) {
                        setState(() {
                          currentKm = value;
                        });
                        controller.setRadiusMeters(value * 1000);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PinnedHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class _MyEventsCarouselCard extends StatelessWidget {
  const _MyEventsCarouselCard({
    required this.event,
    required this.isConfirmed,
    required this.pendingInvitesCount,
    required this.onTap,
    this.distanceLabel,
  });

  final VenueEventResume event;
  final bool isConfirmed;
  final int pendingInvitesCount;
  final VoidCallback onTap;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final start = event.startDateTime;
    final end = start.add(_assumedEventDuration);
    final now = DateTime.now();
    final isLiveNow = now.isAfter(start) && now.isBefore(end);
    final scheduleLabel = isLiveNow
        ? '${start.timeLabel} - ${end.timeLabel}'
        : '${start.dayLabel} ${start.monthLabel} • ${start.timeLabel}';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth * 9 / 16;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: CarouselCard(
            imageUri: event.imageUri,
            overlayMode: CarouselCardOverlayMode.fill,
            overlayAlignment: Alignment.topLeft,
            contentOverlay: SizedBox(
              height: cardHeight,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InviteStatusIcon(
                              isConfirmed: isConfirmed,
                              pendingInvitesCount: pendingInvitesCount,
                              size: 18,
                              backgroundColor:
                                  colorScheme.secondary.withValues(alpha: 0.3),
                            ),
                            if (isLiveNow) ...[
                              const SizedBox(width: 10),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'AGORA',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onError,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            EventInfoRow(
                              icon: Icons.schedule,
                              label: scheduleLabel,
                            ),
                            const SizedBox(height: 4),
                            EventInfoRow(
                              icon: Icons.place_outlined,
                              label: distanceLabel == null
                                  ? event.location
                                  : '${event.location} (${distanceLabel!})',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeeMoreMyEventsCard extends StatelessWidget {
  const _SeeMoreMyEventsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHighest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.more_horiz, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Ver mais',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
