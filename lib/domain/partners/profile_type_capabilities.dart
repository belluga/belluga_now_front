class ProfileTypeCapabilities {
  const ProfileTypeCapabilities({
    required this.isFavoritable,
    required this.isPoiEnabled,
  });

  final bool isFavoritable;
  final bool isPoiEnabled;

  factory ProfileTypeCapabilities.fromJson(Map<String, dynamic>? json) {
    final raw = json ?? const <String, dynamic>{};
    return ProfileTypeCapabilities(
      isFavoritable: raw['is_favoritable'] == true,
      isPoiEnabled: raw['is_poi_enabled'] == true,
    );
  }
}
