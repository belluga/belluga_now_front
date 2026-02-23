import 'package:auto_route/auto_route.dart';
import 'package:belluga_admin_ui/belluga_admin_ui.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/models/tenant_admin_settings_integration_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminSettingsScreen extends StatefulWidget {
  const TenantAdminSettingsScreen({super.key});

  @override
  State<TenantAdminSettingsScreen> createState() =>
      _TenantAdminSettingsScreenState();
}

class _TenantAdminSettingsScreenState extends State<TenantAdminSettingsScreen> {
  final TenantAdminSettingsController _controller =
      GetIt.I.get<TenantAdminSettingsController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  void _openLocalPreferences() {
    context.router.push(const TenantAdminSettingsLocalPreferencesRoute());
  }

  void _openVisualIdentity() {
    context.router.push(const TenantAdminSettingsVisualIdentityRoute());
  }

  void _openTechnicalIntegrations([
    TenantAdminSettingsIntegrationSection initialSection =
        TenantAdminSettingsIntegrationSection.firebase,
  ]) {
    context.router.push(
      TenantAdminSettingsTechnicalIntegrationsRoute(
        initialSection: initialSection,
      ),
    );
  }

  void _openEnvironmentSnapshot() {
    context.router.push(const TenantAdminSettingsEnvironmentSnapshotRoute());
  }

  ThemeMode _themeModeForPreview(ThemeMode? raw) => raw ?? ThemeMode.system;

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Claro',
      ThemeMode.dark => 'Escuro',
      ThemeMode.system => 'Sistema',
    };
  }

  Color _colorFromHex(String raw, Color fallback) {
    final value = raw.trim().replaceFirst('#', '');
    if (value.length != 6) {
      return fallback;
    }
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) {
      return fallback;
    }
    return Color(0xFF000000 | parsed);
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHint(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appData = _controller.appData;
    final firebaseSettings = appData.firebaseSettings;
    final pushSettings = appData.pushSettings;

    return ListView(
      key: TenantAdminSettingsKeys.hubList,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        StreamValueBuilder<ThemeMode?>(
          streamValue: _controller.themeModeStreamValue,
          builder: (context, themeMode) {
            return StreamValueBuilder<double>(
              streamValue: _controller.maxRadiusMetersStreamValue,
              builder: (context, maxRadiusMeters) {
                final currentMeters = maxRadiusMeters.clamp(1000.0, 100000.0);
                final currentKm = (currentMeters / 1000).toStringAsFixed(0);
                return TenantAdminHubCardShell(
                  key: TenantAdminSettingsKeys.hubCardPreferences,
                  onTap: _openLocalPreferences,
                  title: 'Preferências',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(
                        context,
                        label: 'Tema',
                        value: _themeModeLabel(_themeModeForPreview(themeMode)),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        context,
                        label: 'Raio do mapa',
                        value: '$currentKm km',
                      ),
                      _buildHint(context, 'Toque para editar preferências'),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 14),
        StreamValueBuilder<TenantAdminBrandingSettings?>(
          streamValue: _controller.brandingSettingsStreamValue,
          builder: (context, brandingSettings) {
            final neutralColor =
                Theme.of(context).colorScheme.surfaceContainerHighest;
            final primaryHex = brandingSettings?.primarySeedColor ?? '--';
            final secondaryHex = brandingSettings?.secondarySeedColor ?? '--';
            return Semantics(
              identifier: 'tenant_admin_settings_hub_visual_identity_card',
              button: true,
              onTap: _openVisualIdentity,
              child: TenantAdminHubCardShell(
                key: TenantAdminSettingsKeys.hubCardVisualIdentity,
                onTap: _openVisualIdentity,
                title: 'Identidade Visual',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      identifier:
                          'tenant_admin_settings_hub_visual_identity_primary_hex',
                      child: TenantAdminHubColorHexRow(
                        color: _colorFromHex(
                          primaryHex,
                          neutralColor,
                        ),
                        hexValue: primaryHex,
                        label: 'Cor primária',
                        highlighted: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      identifier:
                          'tenant_admin_settings_hub_visual_identity_secondary_hex',
                      child: TenantAdminHubColorHexRow(
                        color: _colorFromHex(
                          secondaryHex,
                          neutralColor,
                        ),
                        hexValue: secondaryHex,
                        label: 'Cor secundária',
                      ),
                    ),
                    _buildHint(
                      context,
                      brandingSettings == null
                          ? 'Identidade visual indisponível. Toque para carregar.'
                          : 'Toque para editar identidade visual',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        TenantAdminHubCardShell(
          key: TenantAdminSettingsKeys.hubCardTechnicalIntegrations,
          title: 'Integrações Técnicas',
          child: Column(
            children: [
              KeyedSubtree(
                key: TenantAdminSettingsKeys.hubIntegrationFirebase,
                child: TenantAdminHubIntegrationRow(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Firebase',
                  subtitle: firebaseSettings == null
                      ? 'Sem configuração ativa'
                      : firebaseSettings.projectId,
                  onTap: () => _openTechnicalIntegrations(
                    TenantAdminSettingsIntegrationSection.firebase,
                  ),
                ),
              ),
              Divider(
                height: 12,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.6),
              ),
              KeyedSubtree(
                key: TenantAdminSettingsKeys.hubIntegrationTelemetry,
                child: TenantAdminHubIntegrationRow(
                  icon: Icons.insights_outlined,
                  title: 'Telemetry',
                  subtitle: appData.telemetrySettings.trackers.isEmpty
                      ? 'Nenhuma integração ativa'
                      : '${appData.telemetrySettings.trackers.length} tracker(es)',
                  onTap: () => _openTechnicalIntegrations(
                    TenantAdminSettingsIntegrationSection.telemetry,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TenantAdminHubCardShell(
          key: TenantAdminSettingsKeys.hubCardEnvironmentSnapshot,
          onTap: _openEnvironmentSnapshot,
          title: 'Snapshot do environment',
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hostname: ${appData.hostname}\nPush: ${pushSettings?.enabled == true ? 'habilitado' : 'desabilitado'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
