import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final sections = <_MenuSection>[
      _MenuSection(
        title: 'Explorar',
        actions: [
          _MenuAction(
            icon: Icons.calendar_month_outlined,
            label: 'Meus eventos',
            helper: 'Veja tudo que você já confirmou',
            onTap: () => context.router.pushPath('/agenda'),
          ),
          _MenuAction(
            icon: Icons.fastfood_outlined,
            label: 'Mercado',
            helper: 'Produtores e experiências gastronômicas',
            onTap: () => context.router.pushPath('/mercado'),
          ),
          _MenuAction(
            icon: Icons.travel_explore_outlined,
            label: 'Explorar experiências',
            helper: 'Descubra o que acontece por perto',
            onTap: () => context.router.pushPath('/experiencias'),
          ),
        ],
      ),
      _MenuSection(
        title: 'Conta',
        actions: [
          _MenuAction(
            icon: Icons.person_outline,
            label: 'Meu perfil',
            helper: 'Dados pessoais, interesses e notificações',
            onTap: () => context.router.pushPath('/profile'),
          ),
          _MenuAction(
            icon: Icons.credit_card_outlined,
            label: 'Pagamentos & parcerias',
            helper: 'Cartões cadastrados e promo codes',
            onTap: () => _showComingSoon(context),
          ),
          _MenuAction(
            icon: Icons.settings_outlined,
            label: 'Configurações',
            helper: 'Preferências, idioma e acessibilidade',
            onTap: () => _showComingSoon(context),
          ),
        ],
      ),
      _MenuSection(
        title: 'Suporte',
        actions: [
          _MenuAction(
            icon: Icons.help_outline,
            label: 'Central de ajuda',
            helper: 'Perguntas frequentes e suporte em tempo real',
            onTap: () => _showComingSoon(context),
          ),
          _MenuAction(
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
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 4),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          itemCount: sections.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            if (index == sections.length) {
              return _LogoutTile(onTap: () => _showComingSoon(context));
            }
            final section = sections[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < section.actions.length; i++)
                        _MenuTile(
                          action: section.actions[i],
                          showDivider: i != section.actions.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            );
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

class _MenuSection {
  const _MenuSection({required this.title, required this.actions});

  final String title;
  final List<_MenuAction> actions;
}

class _MenuAction {
  const _MenuAction({
    required this.icon,
    required this.label,
    required this.helper,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String helper;
  final VoidCallback onTap;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.action, this.showDivider = true});

  final _MenuAction action;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tile = ListTile(
      onTap: action.onTap,
      leading: Icon(action.icon, color: theme.colorScheme.primary),
      title: Text(
        action.label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        action.helper,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    if (!showDivider) {
      return tile;
    }

    return Column(
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 0,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.logout, color: theme.colorScheme.error),
        title: Text(
          'Sair da conta',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Trocar de conta ou encerrar sessão',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
