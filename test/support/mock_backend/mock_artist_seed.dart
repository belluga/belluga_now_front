import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/partners/account_profile_summary.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_text_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

class MockArtistSeed {
  const MockArtistSeed({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.highlight = false,
    this.genres = const [],
  });

  final String id;
  final String name;
  final String avatarUrl;
  final bool highlight;
  final List<String> genres;

  AccountProfileSummary toLinkedAccountProfile() {
    final trimmedAvatarUrl = avatarUrl.trim();
    final avatarValue = trimmedAvatarUrl.isEmpty
        ? null
        : (ThumbUriValue(defaultValue: Uri.parse(trimmedAvatarUrl))
            ..parse(trimmedAvatarUrl));

    return AccountProfileSummary(
      idValue: AccountProfileTextValue(id),
      nameValue: AccountProfileNameValue()..parse(name),
      profileTypeValue: AccountProfileTypeValue('artist'),
      avatarValue: avatarValue,
    );
  }
}
