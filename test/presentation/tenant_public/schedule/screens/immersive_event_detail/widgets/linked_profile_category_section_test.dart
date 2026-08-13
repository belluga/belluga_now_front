import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_overlapping_identity_card.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/widgets/linked_profile_category_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'linked profile cards use dark-safe title contrast in dark theme',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange,
              brightness: Brightness.dark,
            ),
          ),
          home: Scaffold(
            body: LinkedProfileCategorySection(
              title: 'Artists',
              profiles: [
                _buildLinkedProfile(
                  id: 'profile-1',
                  name: 'Artista Noturno',
                  avatarUrl: 'https://tenant.test/media/profile-1-avatar.png',
                ),
              ],
              profileTypeRegistry: null,
              favoriteAccountProfileIds: const {},
              isFavoritable: (_) => true,
              onProfileTap: (_) {},
              onFavoriteTap: (_) {},
            ),
          ),
        ),
      );

      final theme = Theme.of(
        tester.element(find.byKey(const Key('linkedProfileCard_profile-1'))),
      );
      final profileCard = tester.widget<AccountProfileOverlappingIdentityCard>(
        find.byType(AccountProfileOverlappingIdentityCard),
      );

      expect(profileCard.titleStyle?.color, theme.colorScheme.onSurface);
    },
  );
}

EventLinkedAccountProfile _buildLinkedProfile({
  required String id,
  required String name,
  required String avatarUrl,
}) {
  final taxonomyTerms = EventLinkedAccountProfileTaxonomyTerms()
    ..addTerm(
      typeValue: AccountProfileTagValue('genre'),
      nameValue: AccountProfileTagValue('Gênero'),
      valueValue: AccountProfileTagValue('Eletrônica'),
    );

  return EventLinkedAccountProfile(
    idValue: EventLinkedAccountProfileTextValue(id),
    displayNameValue: EventLinkedAccountProfileTextValue(name),
    profileTypeValue: AccountProfileTypeValue('artist'),
    slugValue: SlugValue()..parse(id),
    avatarUrlValue: ThumbUriValue(defaultValue: Uri.parse(avatarUrl)),
    canOpenPublicDetailValue: DomainBooleanValue(
      defaultValue: false,
      isRequired: false,
    )..parse('true'),
    publicDetailPathValue: EventLinkedAccountProfileTextValue('/parceiro/$id'),
    taxonomyTerms: taxonomyTerms,
  );
}
