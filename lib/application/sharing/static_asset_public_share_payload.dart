import 'package:belluga_now/application/invites/invite_from_event_factory.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';

final class StaticAssetPublicSharePayloadBuilder {
  StaticAssetPublicSharePayloadBuilder._();

  static ({String subject, String message}) build({
    required Uri publicUri,
    required String fallbackName,
    PublicStaticAssetModel? asset,
    String? actorDisplayName,
    String? fallbackDescription,
  }) {
    final subject = _resolveSubject(
      asset: asset,
      fallbackName: fallbackName,
    );
    final intro = _resolveIntro(
      actorDisplayName: actorDisplayName,
      subject: subject,
    );
    final description = _resolveDescription(
      asset: asset,
      fallbackDescription: fallbackDescription,
    );
    return (
      subject: subject,
      message: <String>[
        intro,
        if (description != null && description.isNotEmpty) description,
        publicUri.toString(),
      ].join('\n\n'),
    );
  }

  static String _resolveSubject({
    required PublicStaticAssetModel? asset,
    required String fallbackName,
  }) {
    final assetName = asset?.displayName.trim();
    if (assetName != null && assetName.isNotEmpty) {
      return assetName;
    }
    return fallbackName.trim();
  }

  static String _resolveIntro({
    required String? actorDisplayName,
    required String subject,
  }) {
    final actorName = actorDisplayName?.trim();
    if (actorName != null && actorName.isNotEmpty) {
      return '$actorName está te convidando para conhecer $subject.';
    }
    return 'Ei, vi isso e achei que você gostaria: $subject.';
  }

  static String? _resolveDescription({
    required PublicStaticAssetModel? asset,
    required String? fallbackDescription,
  }) {
    final assetContent = asset?.content?.trim();
    if (assetContent != null && assetContent.isNotEmpty) {
      final excerpt = InviteFromEventFactory.stripHtml(assetContent);
      if (excerpt.isNotEmpty) {
        return excerpt;
      }
    }

    final assetBio = asset?.bio?.trim();
    if (assetBio != null && assetBio.isNotEmpty) {
      final excerpt = InviteFromEventFactory.stripHtml(assetBio);
      if (excerpt.isNotEmpty) {
        return excerpt;
      }
    }

    final rawFallback = fallbackDescription?.trim();
    if (rawFallback == null || rawFallback.isEmpty) {
      return null;
    }
    final excerpt = InviteFromEventFactory.stripHtml(rawFallback);
    return excerpt.isEmpty ? null : excerpt;
  }
}
