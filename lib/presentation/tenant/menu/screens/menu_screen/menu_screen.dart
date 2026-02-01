import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/models/menu_section.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/widgets/menu_profile_hero.dart';
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
                return MenuProfileHero(
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
