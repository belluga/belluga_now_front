import 'package:belluga_now/application/invites/invite_from_event_factory.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';

final class AccountProfilePublicSharePayloadBuilder {
  AccountProfilePublicSharePayloadBuilder._();

  static ({String subject, String message}) build({
    required Uri publicUri,
    required String fallbackName,
    AccountProfileModel? profile,
    String? actorDisplayName,
    String? fallbackDescription,
  }) {
    final subject = _resolveSubject(
      profile: profile,
      fallbackName: fallbackName,
    );
    final intro = _resolveIntro(
      actorDisplayName: actorDisplayName,
      subject: subject,
    );
    final description = _resolveDescription(
      profile: profile,
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

  static String? resolveDescription({
    AccountProfileModel? profile,
    String? fallbackDescription,
  }) {
    return _resolveDescription(
      profile: profile,
      fallbackDescription: fallbackDescription,
    );
  }

  static String _resolveSubject({
    required AccountProfileModel? profile,
    required String fallbackName,
  }) {
    final profileName = profile?.name.trim();
    if (profileName != null && profileName.isNotEmpty) {
      return profileName;
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
    required AccountProfileModel? profile,
    required String? fallbackDescription,
  }) {
    final profileContent = profile?.content?.trim();
    if (profileContent != null && profileContent.isNotEmpty) {
      final excerpt = InviteFromEventFactory.stripHtml(profileContent);
      if (excerpt.isNotEmpty) {
        return excerpt;
      }
    }

    final profileBio = profile?.bio?.trim();
    if (profileBio != null && profileBio.isNotEmpty) {
      final excerpt = InviteFromEventFactory.stripHtml(profileBio);
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
