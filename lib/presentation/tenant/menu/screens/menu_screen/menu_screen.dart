import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/models/menu_section.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/widgets/menu_section_card.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    final sections = <MenuSection>[
      MenuSection(
        title: 'Agenda',
        actions: [
          MenuAction(
            icon: Icons.event_available_outlined,
            label: 'Meus eventos confirmados',
            helper: 'Agenda filtrada só com eventos confirmados',
            onTap: () => context.router.push(
              EventSearchRoute(inviteFilter: InviteFilter.confirmedOnly),
            ),
          ),
          MenuAction(
            icon: Icons.history_toggle_off,
            label: 'Eventos passados',
            helper: 'Ver histórico de eventos encerrados',
            onTap: () => context.router.push(
              EventSearchRoute(startWithHistory: true),
            ),
          ),
        ],
      ),
      MenuSection(
        title: 'Explorar',
        actions: [
          MenuAction(
            icon: Icons.map_outlined,
            label: 'Mapa',
            helper: 'Explorar pontos e eventos no mapa',
            onTap: () => context.router.push(const CityMapRoute()),
          ),
          MenuAction(
            icon: BooraIcons.invite_outlined,
            label: 'Convites recebidos',
            helper: 'Eventos onde você foi convidado',
            onTap: () => context.router.push(
              EventSearchRoute(inviteFilter: InviteFilter.invitesAndConfirmed),
            ),
          ),
        ],
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        context.router.replaceAll([TenantHomeRoute()]);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Menu',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 2),
        body: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            itemCount: sections.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ProfileHero(
                  onTapViewProfile: () =>
                      context.router.push(const ProfileRoute()),
                  invitesSent: 0, // TODO(Delphi): Bind to convites enviados (pending/total).
                  invitesAccepted: 0, // TODO(Delphi): Bind to real social score metrics (convites aceitos).
                );
              }
              final section = sections[index - 1];
              return MenuSectionCard(section: section);
            },
          ),
        ),
      ),
    );
  }

}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.onTapViewProfile,
    required this.invitesSent,
    required this.invitesAccepted,
  });

  final VoidCallback onTapViewProfile;
  final int invitesSent;
  final int invitesAccepted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            child: Icon(
              Icons.person,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seu Perfil',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Convites aceitos e presenças confirmadas valem mais que likes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricPill(
                      value: invitesSent,
                      icon: BooraIcons.invite_outlined,
                      iconColor: colorScheme.secondary,
                      backgroundColor:
                          colorScheme.secondary.withValues(alpha: 0.14),
                    ),
                    _MetricPill(
                      value: invitesAccepted,
                      icon: BooraIcons.invite_solid,
                      iconColor: colorScheme.primary,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onTapViewProfile,
            icon:
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final int value;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
