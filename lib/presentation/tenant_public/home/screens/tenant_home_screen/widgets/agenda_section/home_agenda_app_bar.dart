import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/widgets/agenda_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class HomeAgendaAppBar extends StatelessWidget {
  const HomeAgendaAppBar({
    super.key,
    required this.controller,
    this.onFilterPressed,
  });

  final TenantHomeAgendaController controller;
  final VoidCallback? onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final authUserStreamValue = controller.authUserStreamValue;
    if (authUserStreamValue == null) {
      return _buildAgendaAppBar();
    }

    return StreamValueBuilder<UserContract?>(
      streamValue: authUserStreamValue,
      builder: (context, _) => _buildAgendaAppBar(),
    );
  }

  AgendaAppBar _buildAgendaAppBar() {
    return AgendaAppBar(
      controller: controller,
      actions: AgendaAppBarActions(
        showSearch: false,
        leadingActions: [
          _HomeAgendaFilterAction(
            controller: controller,
            onPressed: onFilterPressed,
          ),
        ],
        showRadius: true,
        showInviteFilter: controller.shouldShowInviteFilterAction,
        showHistory: false,
        radiusSheetPresentation: const AgendaRadiusSheetPresentation(
          title: 'Distância Máxima',
          description:
              'Mostraremos apenas eventos acontecendo dentro desse raio a partir de sua localização.',
          helperText: 'Você pode alterar essa preferência quando quiser.',
          confirmButtonLabel: 'Confirmar raio',
        ),
      ),
    );
  }
}

class _HomeAgendaFilterAction extends StatelessWidget {
  const _HomeAgendaFilterAction({
    required this.controller,
    this.onPressed,
  });

  final TenantHomeAgendaController controller;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<DiscoveryFilterCatalog>(
      streamValue: controller.discoveryFilterCatalogStreamValue,
      builder: (context, catalog) {
        if (catalog.filters.isEmpty) {
          return const SizedBox.shrink();
        }

        return StreamValueBuilder<DiscoveryFilterSelection>(
          streamValue: controller.discoveryFilterSelectionStreamValue,
          builder: (context, selection) {
            final colorScheme = Theme.of(context).colorScheme;
            final isActive = selection.isNotEmpty;
            final activeCount = selection.activeCount;
            return IconButton(
              key: const ValueKey<String>('home-agenda-filter-button'),
              tooltip: isActive ? 'Filtros ativos' : 'Filtrar eventos',
              onPressed: onPressed ?? controller.toggleDiscoveryFilterPanel,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive
                        ? Icons.filter_alt_rounded
                        : Icons.filter_alt_outlined,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  if (activeCount > 0)
                    Positioned(
                      key: const ValueKey<String>('home-agenda-filter-badge'),
                      right: -7,
                      top: -7,
                      child: _FilterCounterBadge(count: activeCount),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterCounterBadge extends StatelessWidget {
  const _FilterCounterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
