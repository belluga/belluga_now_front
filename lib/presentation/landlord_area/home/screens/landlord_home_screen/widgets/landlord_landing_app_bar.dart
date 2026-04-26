import 'dart:ui';

import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_ui_state.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/widgets/landlord_brand_image.dart';
import 'package:flutter/material.dart';

class LandlordLandingAppBar extends StatelessWidget {
  const LandlordLandingAppBar({
    super.key,
    required this.state,
    required this.onProblemPressed,
    required this.onSolutionPressed,
    required this.onEcosystemPressed,
    required this.onInstancesPressed,
    required this.onContactPressed,
    required this.onLoginPressed,
    required this.onMenuPressed,
  });

  final LandlordHomeUiState state;
  final VoidCallback onProblemPressed;
  final VoidCallback onSolutionPressed;
  final VoidCallback onEcosystemPressed;
  final VoidCallback onInstancesPressed;
  final VoidCallback onContactPressed;
  final VoidCallback onLoginPressed;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 920;
        final elevated = state.isScrolled || state.isMobileMenuOpen;
        final foreground = elevated ? state.brand.slate : Colors.white;
        final appBar = ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: elevated ? 10 : 0,
              sigmaY: elevated ? 10 : 0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: elevated
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: elevated
                        ? state.brand.slate.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 16,
                    vertical: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Row(
                      children: [
                        LandlordBrandImage(
                          url: null,
                          fallbackLabel: state.brand.appName,
                          width: 128,
                          height: 38,
                          foregroundColor: foreground,
                          backgroundColor: Colors.transparent,
                        ),
                        const Spacer(),
                        if (isDesktop) ...[
                          _NavLink(
                            label: 'Problema',
                            onPressed: onProblemPressed,
                            color: foreground,
                          ),
                          _NavLink(
                            label: 'Solução',
                            onPressed: onSolutionPressed,
                            color: foreground,
                          ),
                          _NavLink(
                            label: 'Ecossistema',
                            onPressed: onEcosystemPressed,
                            color: foreground,
                          ),
                          _NavLink(
                            label: 'Instâncias',
                            onPressed: onInstancesPressed,
                            color: foreground,
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            color: foreground.withValues(alpha: 0.22),
                          ),
                        ],
                        TextButton(
                          onPressed: onLoginPressed,
                          style: TextButton.styleFrom(
                            foregroundColor: foreground,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('Entrar'),
                        ),
                        if (isDesktop)
                          _ContactButton(
                            label: 'Fale com a Equipe',
                            accent: state.brand.accent,
                            onPressed: onContactPressed,
                          )
                        else
                          IconButton(
                            onPressed: onMenuPressed,
                            icon: Icon(
                              state.isMobileMenuOpen ? Icons.close : Icons.menu,
                              color: foreground,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            appBar,
            if (!isDesktop && state.isMobileMenuOpen)
              _MobileMenu(
                state: state,
                onProblemPressed: onProblemPressed,
                onSolutionPressed: onSolutionPressed,
                onEcosystemPressed: onEcosystemPressed,
                onInstancesPressed: onInstancesPressed,
                onContactPressed: onContactPressed,
              ),
          ],
        );
      },
    );
  }
}

class _MobileMenu extends StatelessWidget {
  const _MobileMenu({
    required this.state,
    required this.onProblemPressed,
    required this.onSolutionPressed,
    required this.onEcosystemPressed,
    required this.onInstancesPressed,
    required this.onContactPressed,
  });

  final LandlordHomeUiState state;
  final VoidCallback onProblemPressed;
  final VoidCallback onSolutionPressed;
  final VoidCallback onEcosystemPressed;
  final VoidCallback onInstancesPressed;
  final VoidCallback onContactPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.96),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MobileNavItem(label: 'Problema', onPressed: onProblemPressed),
          _MobileNavItem(label: 'Solução', onPressed: onSolutionPressed),
          _MobileNavItem(label: 'Ecossistema', onPressed: onEcosystemPressed),
          _MobileNavItem(label: 'Instâncias', onPressed: onInstancesPressed),
          const SizedBox(height: 8),
          _ContactButton(
            label: 'Fale com a Equipe',
            accent: state.brand.accent,
            onPressed: onContactPressed,
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: const Color(0xFF0F172A),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
      ),
      child: Text(label),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.label,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text(label),
    );
  }
}
