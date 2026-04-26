import 'package:flutter/material.dart';

class TenantAdminDiscoveryFiltersKeys {
  const TenantAdminDiscoveryFiltersKeys._();

  static const listScreen = ValueKey('tenant_admin_discovery_filters_screen');

  static ValueKey<String> surfaceCard(String surfaceKey) => ValueKey(
        'tenant_admin_discovery_filters_surface_${_safe(surfaceKey)}',
      );

  static ValueKey<String> surfaceScreen(String surfaceKey) => ValueKey(
        'tenant_admin_discovery_filters_surface_screen_${_safe(surfaceKey)}',
      );

  static const addFilterButton =
      ValueKey('tenant_admin_discovery_filters_add_filter');

  static const saveFiltersButton =
      ValueKey('tenant_admin_discovery_filters_save_filters');

  static ValueKey<String> filterRow(String surfaceKey, int index) => ValueKey(
        'tenant_admin_discovery_filters_${_safe(surfaceKey)}_row_$index',
      );

  static ValueKey<String> filterVisualPreview(
    String surfaceKey,
    int index,
  ) =>
      ValueKey(
        'tenant_admin_discovery_filters_${_safe(surfaceKey)}_visual_$index',
      );

  static ValueKey<String> filterRuleButton(String surfaceKey, int index) =>
      ValueKey(
        'tenant_admin_discovery_filters_${_safe(surfaceKey)}_rule_$index',
      );

  static ValueKey<String> filterVisualButton(String surfaceKey, int index) =>
      ValueKey(
        'tenant_admin_discovery_filters_${_safe(surfaceKey)}_visual_button_$index',
      );

  static String _safe(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
