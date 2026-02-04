class ProfileTypeCapabilities {
  const ProfileTypeCapabilities({
    required this.isFavoritable,
    required this.isPoiEnabled,
    required this.hasBio,
    required this.hasTaxonomies,
    required this.hasAvatar,
    required this.hasCover,
    required this.hasEvents,
  });

  final bool isFavoritable;
  final bool isPoiEnabled;
  final bool hasBio;
  final bool hasTaxonomies;
  final bool hasAvatar;
  final bool hasCover;
  final bool hasEvents;

  factory ProfileTypeCapabilities.fromJson(Map<String, dynamic>? json) {
    final raw = json ?? const <String, dynamic>{};
    return ProfileTypeCapabilities(
      isFavoritable: raw['is_favoritable'] == true,
      isPoiEnabled: raw['is_poi_enabled'] == true,
      hasBio: raw['has_bio'] == true,
      hasTaxonomies: raw['has_taxonomies'] == true,
      hasAvatar: raw['has_avatar'] == true,
      hasCover: raw['has_cover'] == true,
      hasEvents: raw['has_events'] == true,
    );
  }
}
