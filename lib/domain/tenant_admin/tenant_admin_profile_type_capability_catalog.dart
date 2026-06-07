import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_key.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminProfileTypeCapabilityCatalog {
  const TenantAdminProfileTypeCapabilityCatalog._();

  static final definitions = <_TenantAdminProfileTypeCapabilityDefinition>[
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.isQueryable,
      defaultValue: TenantAdminFlagValue(true),
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.isPubliclyNavigable,
      defaultValue: TenantAdminFlagValue(true),
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.isPubliclyDiscoverable,
      defaultValue: TenantAdminFlagValue(true),
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.isFavoritable,
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.isInviteable,
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.isPoiEnabled,
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.isReferenceLocationEnabled,
      requiredKeys: {
        TenantAdminProfileTypeCapabilityKey.isPoiEnabled,
      },
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.hasBio,
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.hasContent,
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.hasTaxonomies,
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.hasAvatar,
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.hasCover,
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.hasEvents,
    ),
    _TenantAdminProfileTypeCapabilityDefinition(
      keyValue: TenantAdminProfileTypeCapabilityKey.hasNestedProfileGroups,
    ),
  ];

  static Iterable<TenantAdminProfileTypeCapabilityKey> get keys =>
      definitions.map((definition) => definition.key);

  static TenantAdminFlagValue defaultValueFor(
    TenantAdminProfileTypeCapabilityKey key,
  ) {
    return _definitionFor(key).defaultValue;
  }

  static Iterable<TenantAdminProfileTypeCapabilityKey> requiredKeysFor(
    TenantAdminProfileTypeCapabilityKey key,
  ) {
    return _definitionFor(key).requiredKeys;
  }

  static _TenantAdminProfileTypeCapabilityDefinition _definitionFor(
    TenantAdminProfileTypeCapabilityKey key,
  ) {
    return definitions.firstWhere((definition) => definition.key == key);
  }
}

class _TenantAdminProfileTypeCapabilityDefinition {
  _TenantAdminProfileTypeCapabilityDefinition({
    required this.keyValue,
    TenantAdminFlagValue? defaultValue,
    Set<TenantAdminProfileTypeCapabilityKey>? requiredKeys,
  })  : defaultValue = defaultValue ?? TenantAdminFlagValue(false),
        requiredKeys = Set<TenantAdminProfileTypeCapabilityKey>.unmodifiable(
          requiredKeys ?? const <TenantAdminProfileTypeCapabilityKey>{},
        );

  final TenantAdminProfileTypeCapabilityKey keyValue;
  final TenantAdminFlagValue defaultValue;
  final Set<TenantAdminProfileTypeCapabilityKey> requiredKeys;

  TenantAdminProfileTypeCapabilityKey get key => keyValue;
}
