typedef TenantAdminProfileTypeCapabilityKeyPrimString = String;

enum TenantAdminProfileTypeCapabilityKey {
  isPubliclyDiscoverable,
  isFavoritable,
  isInviteable,
  isPoiEnabled,
  isReferenceLocationEnabled,
  hasBio,
  hasContent,
  hasTaxonomies,
  hasAvatar,
  hasCover,
  hasEvents,
  hasNestedProfileGroups;

  TenantAdminProfileTypeCapabilityKeyPrimString get apiValue => switch (this) {
        TenantAdminProfileTypeCapabilityKey.isPubliclyDiscoverable =>
          'is_publicly_discoverable',
        TenantAdminProfileTypeCapabilityKey.isFavoritable => 'is_favoritable',
        TenantAdminProfileTypeCapabilityKey.isInviteable => 'is_inviteable',
        TenantAdminProfileTypeCapabilityKey.isPoiEnabled => 'is_poi_enabled',
        TenantAdminProfileTypeCapabilityKey.isReferenceLocationEnabled =>
          'is_reference_location_enabled',
        TenantAdminProfileTypeCapabilityKey.hasBio => 'has_bio',
        TenantAdminProfileTypeCapabilityKey.hasContent => 'has_content',
        TenantAdminProfileTypeCapabilityKey.hasTaxonomies => 'has_taxonomies',
        TenantAdminProfileTypeCapabilityKey.hasAvatar => 'has_avatar',
        TenantAdminProfileTypeCapabilityKey.hasCover => 'has_cover',
        TenantAdminProfileTypeCapabilityKey.hasEvents => 'has_events',
        TenantAdminProfileTypeCapabilityKey.hasNestedProfileGroups =>
          'has_nested_profile_groups',
      };
}
