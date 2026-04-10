import 'dart:async';

import 'package:belluga_admin_ui/belluga_admin_ui.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/tenant_admin_settings_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_map_filter_rule_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_map_filter_visual_sheet.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_local_preferences_section.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/widgets/tenant_admin_settings_remote_status_panel.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_field_edit_sheet.dart';
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
    _controller.bindLocalPreferencesFlow();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _controller.init(loadBranding: false);
    await _controller.loadMapUiSettings();
  }

  Future<void> _openDefaultOriginPicker() {
    return context.router.push(
      TenantAdminLocationPickerRoute(
        initialLocation: _controller.currentMapDefaultOriginLocation(),
        backFallbackRoute: const TenantAdminSettingsLocalPreferencesRoute(),
      ),
    );
  }

  Future<void> _editMapFilterKey(int index) async {
    final settings = _controller.mapUiSettingsStreamValue.value;
    if (index < 0 || index >= settings.filters.length) {
      return;
    }
    final current = settings.filters.elementAt(index);
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar chave do filtro',
      label: 'Chave',
      initialValue: current.key,
      confirmLabel: 'Salvar',
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Informe a chave do filtro.';
        }
        return null;
      },
    );
    if (!mounted || result == null) {
      return;
    }
    _controller.updateMapFilterItemKey(index, result.value);
  }

  Future<void> _editMapFilterLabel(int index) async {
    final settings = _controller.mapUiSettingsStreamValue.value;
    if (index < 0 || index >= settings.filters.length) {
      return;
    }
    final current = settings.filters.elementAt(index);
    final result = await showTenantAdminFieldEditSheet(
      context: context,
      title: 'Editar rótulo do filtro',
      label: 'Rótulo',
      initialValue: current.label,
      confirmLabel: 'Salvar',
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Informe o rótulo do filtro.';
        }
        return null;
      },
    );
    if (!mounted || result == null) {
      return;
    }
    _controller.updateMapFilterItemLabel(index, result.value);
  }

  Future<void> _editMapFilterRule(int index) async {
    final settings = _controller.mapUiSettingsStreamValue.value;
    if (index < 0 || index >= settings.filters.length) {
      return;
    }
    await _controller.loadMapFilterRuleCatalog();
    if (!mounted) {
      return;
    }
    final catalog = _controller.mapFilterRuleCatalogStreamValue.value;
    if (catalog.isEmpty) {
      _controller.remoteErrorStreamValue.addValue(
        'Catálogo de tipos/taxonomias indisponível.',
      );
      return;
    }

    final filter = settings.filters.elementAt(index);
    final result = await showTenantAdminMapFilterRuleSheet(
      context: context,
      filter: filter,
      catalog: catalog,
    );

    if (result == null) {
      return;
    }
    _controller.updateMapFilterItemRule(index, result);
  }

  Future<void> _editMapFilterVisual(int index) async {
    final settings = _controller.mapUiSettingsStreamValue.value;
    if (index < 0 || index >= settings.filters.length) {
      return;
    }

    final filter = settings.filters.elementAt(index);
    final result = await showTenantAdminMapFilterVisualSheet(
      context: context,
      filter: filter,
    );
    if (result == null) {
      return;
    }
    _controller.updateMapFilterItemVisual(index, result);
  }

  @override
  Widget build(BuildContext context) {
    final backPolicy = buildTenantAdminCurrentRouteBackPolicy(context);
    return ListView(
      key: TenantAdminSettingsKeys.localPreferencesScreen,
      padding: const EdgeInsets.all(16),
      children: [
        TenantAdminScopedSectionAppBar(
          key: TenantAdminSettingsKeys.localPreferencesScopedAppBar,
          title: 'Preferências',
          backButtonKey: TenantAdminSettingsKeys.localPreferencesBackButton,
          onBack: backPolicy.handleBack,
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsSection(
          title: 'Ajustes locais',
          description: 'Tema local e alcance de mapa do operador admin.',
          icon: Icons.tune_rounded,
          child: TenantAdminSettingsLocalPreferencesSection(
            controller: _controller,
            onOpenDefaultOriginPicker: _openDefaultOriginPicker,
            onAddMapFilter: _controller.addMapFilterItem,
            onEditMapFilterKey: _editMapFilterKey,
            onEditMapFilterLabel: _editMapFilterLabel,
            onEditMapFilterRule: _editMapFilterRule,
            onEditMapFilterVisual: _editMapFilterVisual,
            onRemoveMapFilter: _controller.removeMapFilterItem,
            onMoveMapFilterUp: _controller.moveMapFilterItemUp,
            onMoveMapFilterDown: _controller.moveMapFilterItemDown,
          ),
        ),
        const SizedBox(height: 12),
        TenantAdminSettingsRemoteStatusPanel(
          controller: _controller,
          onReload: _controller.loadMapUiSettings,
        ),
      ],
    );
  }
}
