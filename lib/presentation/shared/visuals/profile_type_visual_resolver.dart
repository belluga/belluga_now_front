import 'package:belluga_now/domain/partners/profile_type_visual.dart';
import 'package:belluga_now/presentation/shared/icons/map_marker_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';

export 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';

class ProfileTypeVisualResolver {
  const ProfileTypeVisualResolver._();

  static ResolvedProfileTypeVisual? resolve({
    required ProfileTypeVisual? visual,
    String? avatarUrl,
    String? coverUrl,
    String? typeAssetUrl,
  }) {
    if (visual == null || !visual.isValid) {
      return null;
    }

    if (visual.isImage) {
      final imageUrl = switch (visual.imageSource) {
        ProfileTypeVisualImageSource.avatar => _normalizeUrl(avatarUrl),
        ProfileTypeVisualImageSource.cover => _normalizeUrl(coverUrl),
        ProfileTypeVisualImageSource.typeAsset =>
          _normalizeUrl(typeAssetUrl ?? visual.imageUrl),
        null => null,
      };
      if (imageUrl == null) {
        return null;
      }
      return ResolvedProfileTypeVisual.image(imageUrl: imageUrl);
    }

    return ResolvedProfileTypeVisual.icon(
      iconData: MapMarkerVisualResolver.resolveIcon(visual.icon),
      backgroundColor: MapMarkerVisualResolver.tryParseHexColor(visual.color),
      iconColor: MapMarkerVisualResolver.tryParseHexColor(visual.iconColor),
    );
  }

  static String? _normalizeUrl(String? rawUrl) {
    final value = rawUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}
