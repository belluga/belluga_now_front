import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_registry.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_key_value.dart';
import 'package:belluga_now/presentation/shared/visuals/profile_type_visual_resolver.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';

class AccountProfileVisualResolver {
  const AccountProfileVisualResolver._();

  static ResolvedAccountProfileVisual resolve({
    required AccountProfileModel accountProfile,
    required ProfileTypeRegistry? registry,
  }) =>
      resolvePreview(
        profileType: accountProfile.type,
        avatarUrl: accountProfile.avatarUrl,
        coverUrl: accountProfile.coverUrl,
        registry: registry,
      );

  static ResolvedAccountProfileVisual resolvePreview({
    required ProfileTypeRegistry? registry,
    String? profileType,
    String? avatarUrl,
    String? coverUrl,
  }) {
    final normalizedType = profileType?.trim();
    final typeKey = (normalizedType != null && normalizedType.isNotEmpty)
        ? ProfileTypeKeyValue(normalizedType)
        : null;
    final typeLabel = typeKey == null
        ? ''
        : (registry?.labelForType(typeKey) ?? normalizedType ?? '');
    final typeVisual = ProfileTypeVisualResolver.resolve(
      visual: typeKey == null ? null : registry?.visualForType(typeKey),
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
    final typeVisualImageUrl =
        typeVisual?.isImage == true ? _normalize(typeVisual?.imageUrl) : null;
    final surfaceImageUrl = _normalize(coverUrl) ??
        _normalize(avatarUrl) ??
        typeVisualImageUrl;
    final compactImageUrl = _normalize(avatarUrl) ??
        _normalize(coverUrl) ??
        typeVisualImageUrl;
    final identityAvatarUrl = _normalize(avatarUrl);

    return ResolvedAccountProfileVisual(
      typeLabel: typeLabel,
      typeVisual: typeVisual,
      surfaceImageUrl: surfaceImageUrl,
      compactImageUrl: compactImageUrl,
      identityAvatarUrl: identityAvatarUrl,
      themeSeedColor:
          surfaceImageUrl == null ? typeVisual?.backgroundColor : null,
    );
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
