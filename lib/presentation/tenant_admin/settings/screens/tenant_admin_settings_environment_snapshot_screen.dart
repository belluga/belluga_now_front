import 'package:belluga_admin_ui/belluga_admin_ui.dart';
import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_environment_snapshot_section.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_scoped_section_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantAdminSettingsEnvironmentSnapshotScreen extends StatefulWidget {
  const TenantAdminSettingsEnvironmentSnapshotScreen({super.key});

  @override
  State<TenantAdminSettingsEnvironmentSnapshotScreen> createState() =>
      _TenantAdminSettingsEnvironmentSnapshotScreenState();
}

class _TenantAdminSettingsEnvironmentSnapshotScreenState
    extends State<TenantAdminSettingsEnvironmentSnapshotScreen> {
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
      key: TenantAdminSettingsKeys.environmentSnapshotScreen,
      padding: const EdgeInsets.all(16),
      children: [
        TenantAdminScopedSectionAppBar(
          key: TenantAdminSettingsKeys.environmentSnapshotScopedAppBar,
          title: 'Snapshot do environment',
          backButtonKey: TenantAdminSettingsKeys.environmentSnapshotBackButton,
          onBack: _handleBack,
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsSection(
          title: 'Runtime do tenant',
          description: 'Leitura dos dados ativos no runtime do app admin.',
          icon: Icons.info_outline,
          child: TenantAdminSettingsEnvironmentSnapshotSection(
            controller: _controller,
          ),
        ),
      ],
    );
  }
}
