import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
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

  EventLinkedAccountProfile toLinkedAccountProfile() {
    final trimmedAvatarUrl = avatarUrl.trim();
    final avatarValue = trimmedAvatarUrl.isEmpty
        ? null
        : (ThumbUriValue(defaultValue: Uri.parse(trimmedAvatarUrl))
          ..parse(trimmedAvatarUrl));

    return EventLinkedAccountProfile(
      idValue: EventLinkedAccountProfileTextValue(id),
      displayNameValue: EventLinkedAccountProfileTextValue(name),
      profileTypeValue: AccountProfileTypeValue('artist'),
      avatarUrlValue: avatarValue,
      partyTypeValue: EventLinkedAccountProfileTextValue('artist'),
    );
  }
}
