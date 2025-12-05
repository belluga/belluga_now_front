import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/common/widgets/main_logo.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/models/menu_section.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/controllers/menu_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/widgets/menu_logout_tile.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/widgets/menu_section_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final MenuScreenController _controller =
      GetIt.I.get<MenuScreenController>();
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
          itemCount: sections.length + 3,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ProfileHero(
                  onTapViewProfile: () => _showComingSoon(context));
            }
            if (index == 1) {
              return StreamValueBuilder<ThemeMode?>(
                streamValue: _controller.themeModeStreamValue,
                builder: (context, mode) {
                  final isDark = mode == ThemeMode.dark;
                  return SwitchListTile.adaptive(
                    value: isDark,
                    onChanged: (value) => _controller
                        .setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
                    title: const Text('Tema escuro'),
                    subtitle: Text(
                      isDark ? 'Usando tema escuro' : 'Usando tema claro',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              );
            }
            if (index == sections.length + 2) {
              return MenuLogoutTile(onTap: () => _showComingSoon(context));
            }
            final section = sections[index - 2];
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.onTapViewProfile});

  final VoidCallback onTapViewProfile;

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
                  'Complete seus dados e personalize notificações.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _ChipPill(
                      label: 'Editar perfil',
                      icon: Icons.edit_outlined,
                      onTap: onTapViewProfile,
                    ),
                    _ChipPill(
                      label: 'Notificações',
                      icon: Icons.notifications_none,
                      onTap: onTapViewProfile,
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

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
