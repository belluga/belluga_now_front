import 'package:belluga_admin_ui/belluga_admin_ui.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_local_preferences_section.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_scoped_section_app_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantAdminSettingsLocalPreferencesScreen extends StatefulWidget {
  const TenantAdminSettingsLocalPreferencesScreen({super.key});

  @override
  State<TenantAdminSettingsLocalPreferencesScreen> createState() =>
      _TenantAdminSettingsLocalPreferencesScreenState();
}

class _TenantAdminSettingsLocalPreferencesScreenState
    extends State<TenantAdminSettingsLocalPreferencesScreen> {
  final TenantAdminSettingsController _controller =
      GetIt.I.get<TenantAdminSettingsController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  void _handleBack() {
    if (context.router.canPop()) {
      context.router.pop();
      return;
    }
    context.router.replace(const TenantAdminSettingsRoute());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: TenantAdminSettingsKeys.localPreferencesScreen,
      padding: const EdgeInsets.all(16),
      children: [
        TenantAdminScopedSectionAppBar(
          key: TenantAdminSettingsKeys.localPreferencesScopedAppBar,
          title: 'Preferências',
          backButtonKey: TenantAdminSettingsKeys.localPreferencesBackButton,
          onBack: _handleBack,
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsSection(
          title: 'Ajustes locais',
          description: 'Tema local e alcance de mapa do operador admin.',
          icon: Icons.tune_rounded,
          child: TenantAdminSettingsLocalPreferencesSection(
            controller: _controller,
          ),
        ),
      ],
    );
  }
}
