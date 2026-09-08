import 'package:belluga_now/domain/partners/value_objects/account_profile_external_link_url_value.dart';

enum AccountProfileExternalLinkType {
  instagram,
  facebook,
  youtube,
  tiktok,
  spotify,
  website;

  String get wireValue => switch (this) {
    instagram => 'instagram',
    facebook => 'facebook',
    youtube => 'youtube',
    tiktok => 'tiktok',
    spotify => 'spotify',
    website => 'website',
  };

  String get semanticLabel => switch (this) {
    instagram => 'Instagram',
    facebook => 'Facebook',
    youtube => 'YouTube',
    tiktok => 'TikTok',
    spotify => 'Spotify',
    website => 'Website',
  };

  bool accepts(AccountProfileExternalLinkUrlValue url) {
    if (this == website) return true;
    final acceptedHosts = switch (this) {
      instagram => const {'instagram.com', 'www.instagram.com'},
      facebook => const {'facebook.com', 'www.facebook.com', 'm.facebook.com'},
      youtube => const {
        'youtube.com',
        'www.youtube.com',
        'm.youtube.com',
        'youtu.be',
      },
      tiktok => const {'tiktok.com', 'www.tiktok.com'},
      spotify => const {'open.spotify.com', 'spotify.link'},
      website => const <String>{},
    };
    return acceptedHosts.contains(url.value.host.toLowerCase()) &&
        url.value.pathSegments.any((segment) => segment.isNotEmpty);
  }
}
