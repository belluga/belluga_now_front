import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/landlord_area/auth/controllers/landlord_login_controller.dart';
import 'package:belluga_now/presentation/landlord_area/auth/widgets/landlord_login_sheet.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/widgets/landlord_pill.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {
  final LandlordHomeScreenController _controller =
      GetIt.I.get<LandlordHomeScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return StreamValueBuilder<LandlordHomeUiState>(
      streamValue: _controller.uiStateStreamValue,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Bóora! Landlord'),
            actions: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Chip(
                  avatar: Icon(
                    state.canAccessAdminArea
                        ? Icons.verified_user_outlined
                        : Icons.security_outlined,
                    size: 18,
                  ),
                  label: Text(
                      state.canAccessAdminArea ? 'Admin ativo' : 'Landlord'),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bóora! Control Center',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Orquestre tenants, padronize experiências e escale a plataforma com consistência.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        LandlordPill(
                          icon: Icons.hub_outlined,
                          label: 'Multi-tenant',
                        ),
                        LandlordPill(
                          icon: Icons.insights_outlined,
                          label: 'Observabilidade',
                        ),
                        LandlordPill(
                          icon: Icons.lock_outline,
                          label: 'Governança',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tenants atuais',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (state.tenants.isEmpty)
                        Text(
                          'Nenhum tenant disponível no bootstrap atual.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        ...state.tenants.map(
                          (tenant) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.apartment_outlined),
                            title: Text(tenant),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (state.canAccessAdminArea)
                FilledButton.icon(
                  onPressed: _openAdminArea,
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Acessar área admin'),
                )
              else
                FilledButton.icon(
                  onPressed: _openLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar como Admin'),
                ),
              const SizedBox(height: 8),
              Text(
                state.canAccessAdminArea
                    ? 'Sessão ativa. Você já pode entrar na área administrativa.'
                    : 'Faça login de landlord para habilitar a área administrativa.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LandlordLoginController get _landlordLoginController =>
      GetIt.I.get<LandlordLoginController>();

  Future<void> _openLogin() async {
    final didLogin = await showLandlordLoginSheet(
      context,
      controller: _landlordLoginController,
    );
    _controller.refreshUiState();
    if (!didLogin || !_controller.canAccessAdminArea) {
      return;
    }
    _openAdminArea();
  }

  bool _openAdminArea() {
    if (!_controller.canAccessAdminArea) return false;
    final routerScope = StackRouterScope.of(context, watch: false);
    final router = routerScope?.controller;
    if (router == null) {
      return false;
    }

    router.replaceAll([const TenantAdminShellRoute()]);
    return true;
  }
}
