import 'dart:async';

import 'package:belluga_admin_ui/belluga_admin_ui.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/models/tenant_admin_settings_integration_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_firebase_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_push_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_remote_status_panel.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_telemetry_section.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_scoped_section_app_bar.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantAdminSettingsTechnicalIntegrationsScreen extends StatefulWidget {
  const TenantAdminSettingsTechnicalIntegrationsScreen({
    super.key,
    this.initialSection = TenantAdminSettingsIntegrationSection.firebase,
  });

  final TenantAdminSettingsIntegrationSection initialSection;

  @override
  State<TenantAdminSettingsTechnicalIntegrationsScreen> createState() =>
      _TenantAdminSettingsTechnicalIntegrationsScreenState();
}

class _TenantAdminSettingsTechnicalIntegrationsScreenState
    extends State<TenantAdminSettingsTechnicalIntegrationsScreen> {
  final TenantAdminSettingsController _controller =
      GetIt.I.get<TenantAdminSettingsController>();

  final GlobalKey _firebaseSectionKey = GlobalKey();
  final GlobalKey _pushSectionKey = GlobalKey();
  final GlobalKey _telemetrySectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller.init();
    unawaited(_controller.loadTechnicalIntegrationsSettings());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusInitialSection();
    });
  }

  void _handleBack() {
    if (context.router.canPop()) {
      context.router.pop();
      return;
    }
    context.router.replace(const TenantAdminSettingsRoute());
  }

  Future<void> _focusInitialSection() async {
    if (!mounted) {
      return;
    }
    final targetKey = switch (widget.initialSection) {
      TenantAdminSettingsIntegrationSection.firebase => _firebaseSectionKey,
      TenantAdminSettingsIntegrationSection.push => _pushSectionKey,
      TenantAdminSettingsIntegrationSection.telemetry => _telemetrySectionKey,
    };
    final targetContext = targetKey.currentContext;
    if (targetContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.08,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: TenantAdminSettingsKeys.technicalIntegrationsScreen,
      padding: const EdgeInsets.all(16),
      children: [
        TenantAdminScopedSectionAppBar(
          key: TenantAdminSettingsKeys.technicalIntegrationsScopedAppBar,
          title: 'Integrações técnicas',
          backButtonKey:
              TenantAdminSettingsKeys.technicalIntegrationsBackButton,
          onBack: _handleBack,
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsRemoteStatusPanel(
          controller: _controller,
          onReload: _controller.loadTechnicalIntegrationsSettings,
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _firebaseSectionKey,
          child: TenantAdminSettingsSection(
            title: 'Firebase',
            description: 'Banco de dados e autenticação.',
            icon: Icons.local_fire_department_outlined,
            child: TenantAdminSettingsFirebaseSection(
              controller: _controller,
            ),
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _pushSectionKey,
          child: TenantAdminSettingsSection(
            title: 'Push',
            description: 'TTL e limites de envio por janela.',
            icon: Icons.notifications_active_outlined,
            child: TenantAdminSettingsPushSection(
              controller: _controller,
            ),
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _telemetrySectionKey,
          child: TenantAdminSettingsSection(
            title: 'Telemetry',
            description: 'Trackers de métricas por integração.',
            icon: Icons.insights_outlined,
            child: TenantAdminSettingsTelemetrySection(
              controller: _controller,
            ),
          ),
        ),
      ],
    );
  }
}
