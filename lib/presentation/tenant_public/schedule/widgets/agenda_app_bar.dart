export 'agenda_app_bar_actions.dart';
export 'agenda_radius_sheet_presentation.dart';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/agenda_app_bar_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/widgets/agenda_app_bar_actions.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/widgets/agenda_radius_sheet_presentation.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AgendaAppBar extends StatelessWidget {
  AgendaAppBar({
    super.key,
    required this.controller,
    this.onBack,
    this.actions = const AgendaAppBarActions(),
  }) : assert(!actions.showBack || onBack != null);

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
        final isSearchActive = actions.showSearch && isActive;
        final showBack = actions.showBack;
        return AppBar(
          primary: false,
          toolbarHeight: kToolbarHeight,
          automaticallyImplyLeading: false,
          leading: showBack
              ? IconButton(
                  tooltip: 'Voltar',
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          leadingWidth: showBack ? null : 0,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSearchActive
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
            if (!isSearchActive && actions.showSearch)
              IconButton(
                tooltip: 'Buscar eventos',
                onPressed: controller.toggleSearchMode,
                icon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            if (!isSearchActive && actions.showRadius)
              StreamValueBuilder<bool>(
                streamValue: controller.isRadiusRefreshLoadingStreamValue,
                builder: (context, isRadiusLoading) {
                  return StreamValueBuilder<double>(
                    streamValue: controller.maxRadiusMetersStreamValue,
                    builder: (context, maxRadiusMeters) {
                      return StreamValueBuilder<double>(
                        streamValue: controller.radiusMetersStreamValue,
                        builder: (context, radiusMeters) {
                          return StreamValueBuilder<bool>(
                            streamValue:
                                controller.isRadiusActionCompactStreamValue,
                            builder: (context, isCompact) {
                              final onPressed = isRadiusLoading
                                  ? null
                                  : () => _showRadiusSelector(
                                        context,
                                        radiusMeters,
                                        controller.minRadiusMeters,
                                        maxRadiusMeters,
                                        actions.radiusSheetPresentation,
                                      );
                              final tooltip = isRadiusLoading
                                  ? 'Atualizando raio...'
                                  : 'Raio ${_formatRadiusLabel(radiusMeters)}';

                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  final slideAnimation = Tween<Offset>(
                                    begin: const Offset(0.08, 0),
                                    end: Offset.zero,
                                  ).animate(animation);
                                  final scaleAnimation = Tween<double>(
                                    begin: 0.92,
                                    end: 1,
                                  ).animate(animation);
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: slideAnimation,
                                      child: ScaleTransition(
                                        scale: scaleAnimation,
                                        child: SizeTransition(
                                          sizeFactor: animation,
                                          axis: Axis.horizontal,
                                          axisAlignment: 1,
                                          child: child,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: isCompact
                                    ? _buildCompactRadiusAction(
                                        context: context,
                                        radiusMeters: radiusMeters,
                                        tooltip: tooltip,
                                        onPressed: onPressed,
                                        isLoading: isRadiusLoading,
                                      )
                                    : _buildExpandedRadiusAction(
                                        context: context,
                                        radiusMeters: radiusMeters,
                                        tooltip: tooltip,
                                        onPressed: onPressed,
                                        isLoading: isRadiusLoading,
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
            if (!isSearchActive && actions.showInviteFilter)
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
            if (!isSearchActive && actions.showHistory)
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

  Widget _buildExpandedRadiusAction({
    required BuildContext context,
    required double radiusMeters,
    required String tooltip,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        key: const ValueKey<String>('agenda-radius-expanded'),
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: Tooltip(
          message: tooltip,
          child: FilledButton.tonalIcon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 10, 8),
            ),
            icon: isLoading
                ? SizedBox.square(
                    key: const ValueKey<String>('agenda-radius-loading'),
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onSecondaryContainer,
                      ),
                    ),
                  )
                : const Icon(Icons.place_outlined, size: 18),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Até ${_formatRadiusLabel(radiusMeters)}'),
                const SizedBox(width: 2),
                const Icon(Icons.expand_more_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRadiusAction({
    required BuildContext context,
    required double radiusMeters,
    required String tooltip,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        key: const ValueKey<String>('agenda-radius-compact'),
        padding: const EdgeInsetsDirectional.only(end: 4),
        child: Tooltip(
          message: tooltip,
          child: IconButton(
            key: const ValueKey<String>('agenda-radius-compact-button'),
            onPressed: onPressed,
            style: IconButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              backgroundColor: Colors.transparent,
              overlayColor:
                  colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(58, 44),
              padding: EdgeInsets.zero,
            ),
            icon: SizedBox(
              width: 58,
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 0,
                    child: isLoading
                        ? SizedBox.square(
                            key:
                                const ValueKey<String>('agenda-radius-loading'),
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : const Icon(Icons.place_outlined, size: 20),
                  ),
                  if (!isLoading)
                    Positioned(
                      top: 16,
                      child: Container(
                        key: const ValueKey<String>(
                            'agenda-radius-compact-badge'),
                        constraints: const BoxConstraints(minWidth: 42),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _formatRadiusLabel(radiusMeters),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontSize: 10,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatRadiusLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(0)} km';
  }

  Future<void> _showRadiusSelector(
    BuildContext context,
    double _selectedMeters,
    double minRadiusMeters,
    double maxRadiusMeters,
    AgendaRadiusSheetPresentation? presentation,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final minRadiusKm = minRadiusMeters / 1000;
    final maxKm = (maxRadiusMeters / 1000) < minRadiusKm
        ? minRadiusKm
        : (maxRadiusMeters / 1000);
    var draftRadiusKm = (_selectedMeters / 1000).clamp(minRadiusKm, maxKm);
    final initialRadiusKm = draftRadiusKm;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomSafeArea = MediaQuery.viewPaddingOf(context).bottom;
            final currentLabel = draftRadiusKm.toStringAsFixed(0);
            final requiresExplicitConfirmation =
                presentation?.requiresExplicitConfirmation ?? false;
            final didChange = (draftRadiusKm - initialRadiusKm).abs() >= 0.001;

            if (requiresExplicitConfirmation && presentation != null) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    24 + bottomSafeArea,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        presentation.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 56,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(120),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 28),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                          ),
                          children: [
                            TextSpan(text: currentLabel),
                            TextSpan(
                              text: ' km',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Slider(
                        value: draftRadiusKm,
                        min: minRadiusKm,
                        max: maxKm,
                        divisions: (maxKm - minRadiusKm).round().clamp(1, 200),
                        onChanged: (value) {
                          setModalState(() {
                            draftRadiusKm = value;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(
                              '${minRadiusKm.toStringAsFixed(0)} km',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${maxKm.toStringAsFixed(0)} km',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withAlpha(140),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withAlpha(40),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                presentation.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (presentation.helperText case final helperText?) ...[
                        const SizedBox(height: 14),
                        Text(
                          helperText,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: didChange
                              ? () {
                                  controller.setRadiusMeters(
                                    draftRadiusKm * 1000,
                                  );
                                  context.router.maybePop();
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(presentation.confirmButtonLabel!),
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle_outline, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24 + bottomSafeArea,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (presentation != null) ...[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.place_outlined,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        presentation.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        presentation.description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      Icon(
                        Icons.my_location_outlined,
                        size: 28,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      '$currentLabel km',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: draftRadiusKm,
                      min: minRadiusKm,
                      max: maxKm,
                      divisions: (maxKm - minRadiusKm).round().clamp(1, 200),
                      onChanged: (value) {
                        setModalState(() {
                          draftRadiusKm = value;
                        });
                      },
                      onChangeEnd: (value) {
                        controller.setRadiusMeters(value * 1000);
                      },
                    ),
                    if (presentation?.helperText case final helperText?)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          helperText,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
