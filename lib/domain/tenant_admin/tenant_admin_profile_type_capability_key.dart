typedef TenantAdminProfileTypeCapabilityKeyPrimString = String;

enum TenantAdminProfileTypeCapabilityKey {
  isQueryable,
  isPubliclyNavigable,
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
  hasGallery,
  hasNestedProfileGroups,
  hasContactChannels;

  TenantAdminProfileTypeCapabilityKeyPrimString get apiValue => switch (this) {
        TenantAdminProfileTypeCapabilityKey.isQueryable => 'is_queryable',
        TenantAdminProfileTypeCapabilityKey.isPubliclyNavigable =>
          'is_publicly_navigable',
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
        TenantAdminProfileTypeCapabilityKey.hasGallery => 'has_gallery',
        TenantAdminProfileTypeCapabilityKey.hasNestedProfileGroups =>
          'has_nested_profile_groups',
        TenantAdminProfileTypeCapabilityKey.hasContactChannels =>
          'has_contact_channels',
      };
}
