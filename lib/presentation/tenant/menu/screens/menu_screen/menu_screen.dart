import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/models/menu_section.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/widgets/menu_logout_tile.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/widgets/menu_section_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <MenuSection>[
      MenuSection(
        title: 'Explorar',
        actions: [
          MenuAction(
            icon: Icons.calendar_month_outlined,
            label: 'Meus eventos',
            helper: 'Veja tudo que você já confirmou',
            onTap: () => context.router.pushPath('/agenda'),
          ),
        ],
      ),
      MenuSection(
        title: 'Conta',
        actions: [
          MenuAction(
            icon: Icons.person_outline,
            label: 'Meu perfil',
            helper: 'Dados pessoais, interesses e notificações',
            onTap: () => context.router.pushPath('/profile'),
          ),
          MenuAction(
            icon: Icons.credit_card_outlined,
            label: 'Pagamentos & parcerias',
            helper: 'Cartões cadastrados e promo codes',
            onTap: () => _showComingSoon(context),
          ),
          MenuAction(
            icon: Icons.settings_outlined,
            label: 'Configurações',
            helper: 'Preferências, idioma e acessibilidade',
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
      MenuSection(
        title: 'Suporte',
        actions: [
          MenuAction(
            icon: Icons.help_outline,
            label: 'Central de ajuda',
            helper: 'Perguntas frequentes e suporte em tempo real',
            onTap: () => _showComingSoon(context),
          ),
          MenuAction(
            icon: Icons.policy_outlined,
            label: 'Políticas & privacidade',
            helper: 'Termos, Privacidade e uso responsável',
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const MainLogo(),
      ),
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 3),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          itemCount: sections.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            if (index == sections.length) {
              return MenuLogoutTile(onTap: () => _showComingSoon(context));
            }
            final section = sections[index];
            return MenuSectionCard(section: section);
          },
        ),
      ),
    );
  }

  static void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Função disponível em breve.'),
      ),
    );
  }
}
