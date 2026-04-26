import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';

class TenantAdminDiscoveryFilterSurfaceDefinition {
  const TenantAdminDiscoveryFilterSurfaceDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.target,
    required this.primarySelectionMode,
    required this.allowedSources,
    required this.supportsMarkerOverride,
  });

  final String key;
  final String title;
  final String description;
  final String target;
  final String primarySelectionMode;
  final List<TenantAdminMapFilterSource> allowedSources;
  final bool supportsMarkerOverride;

  static const map = TenantAdminDiscoveryFilterSurfaceDefinition(
    key: 'public_map.primary',
    title: 'Mapa',
    description: 'Filtros primários exibidos sobre o mapa público.',
    target: 'map_poi',
    primarySelectionMode: 'single',
    allowedSources: <TenantAdminMapFilterSource>[
      TenantAdminMapFilterSource.event,
      TenantAdminMapFilterSource.accountProfile,
      TenantAdminMapFilterSource.staticAsset,
    ],
    supportsMarkerOverride: true,
  );

  static const homeEvents = TenantAdminDiscoveryFilterSurfaceDefinition(
    key: 'home.events',
    title: 'Eventos na Tela Principal',
    description: 'Filtros de eventos exibidos na agenda da Home.',
    target: 'event_occurrence',
    primarySelectionMode: 'single',
    allowedSources: <TenantAdminMapFilterSource>[
      TenantAdminMapFilterSource.event,
    ],
    supportsMarkerOverride: false,
  );

  static const accountDiscovery = TenantAdminDiscoveryFilterSurfaceDefinition(
    key: 'discovery.account_profiles',
    title: 'Descoberta de Perfis',
    description: 'Filtros exibidos na descoberta de Account Profiles.',
    target: 'account_profile',
    primarySelectionMode: 'single',
    allowedSources: <TenantAdminMapFilterSource>[
      TenantAdminMapFilterSource.accountProfile,
    ],
    supportsMarkerOverride: false,
  );

  static const values = <TenantAdminDiscoveryFilterSurfaceDefinition>[
    map,
    homeEvents,
    accountDiscovery,
  ];

  static const adminConfigurableValues =
      <TenantAdminDiscoveryFilterSurfaceDefinition>[
    map,
  ];

  static TenantAdminDiscoveryFilterSurfaceDefinition? byKey(String key) {
    final normalized = key.trim().toLowerCase();
    for (final surface in values) {
      if (surface.key == normalized) {
        return surface;
      }
    }
    return null;
  }
}
