class ProfileTypeCapabilities {
  const ProfileTypeCapabilities({
    required this.isFavoritable,
    required this.isPoiEnabled,
    required this.hasBio,
    required this.hasContent,
    required this.hasTaxonomies,
    required this.hasAvatar,
    required this.hasCover,
    required this.hasEvents,
  });

  final bool isFavoritable;
  final bool isPoiEnabled;
  final bool hasBio;
  final bool hasContent;
  final bool hasTaxonomies;
  final bool hasAvatar;
  final bool hasCover;
  final bool hasEvents;
}
