import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AgendaAppBar extends StatelessWidget {
  const AgendaAppBar({
    super.key,
    required this.controller,
    this.onBack,
    this.actions = const AgendaAppBarActions(),
  });

  final AgendaAppBarController controller;
  final VoidCallback? onBack;
  final AgendaAppBarActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamValueBuilder<bool>(
      streamValue: controller.searchActiveStreamValue,
      builder: (context, isActive) {
        final showBack = actions.showBack;
        return AppBar(
          primary: false,
          toolbarHeight: kToolbarHeight,
          automaticallyImplyLeading: false,
          leading: showBack
              ? IconButton(
                  tooltip: 'Voltar',
                  onPressed: onBack ?? () => context.router.maybePop(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          leadingWidth: showBack ? null : 0,
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
            if (!isActive && actions.showSearch)
              IconButton(
                tooltip: 'Buscar eventos',
                onPressed: controller.toggleSearchMode,
                icon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (!isActive && actions.showRadius)
              StreamValueBuilder<double>(
                streamValue: controller.maxRadiusMetersStreamValue,
                builder: (context, maxRadiusMeters) {
                  return StreamValueBuilder<double>(
                    streamValue: controller.radiusMetersStreamValue,
                    builder: (context, radiusMeters) {
                      return IconButton(
                        tooltip: 'Raio ${_formatRadiusLabel(radiusMeters)}',
                        onPressed: () => _showRadiusSelector(
                          context,
                          radiusMeters,
                          maxRadiusMeters,
                        ),
                        icon: Icon(
                          Icons.radar,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  );
                },
              ),
            if (!isActive && actions.showInviteFilter)
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
            if (!isActive && actions.showHistory)
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

class AgendaAppBarActions {
  const AgendaAppBarActions({
    this.showBack = false,
    this.showSearch = true,
    this.showRadius = true,
    this.showInviteFilter = true,
    this.showHistory = true,
  });

  final bool showBack;
  final bool showSearch;
  final bool showRadius;
  final bool showInviteFilter;
  final bool showHistory;
}
