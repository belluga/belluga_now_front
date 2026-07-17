import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_overlapping_identity_card.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_type_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('treats a blank avatar URL as no leading visual', (tester) async {
    const cardKey = Key('blankAvatarIdentityCard');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 344,
            child: AccountProfileOverlappingIdentityCard(
              cardKey: cardKey,
              name: 'Perfil sem imagem',
              visual: const ResolvedAccountProfileVisual(
                typeLabel: '',
                typeVisual: null,
                surfaceImageUrl: null,
                compactImageUrl: null,
                identityAvatarUrl: '   ',
                themeSeedColor: null,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(cardKey), findsOneWidget);
    expect(find.byType(AccountProfileTypeAvatar), findsNothing);
  });

  testWidgets('wraps every tag and grows the identity card', (tester) async {
    const cardKey = Key('overlappingIdentityCard');
    const tags = <String>[
      'Cultura',
      'Música',
      'Gastronomia',
      'Ao ar livre',
      'Acessível',
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 344,
              child: AccountProfileOverlappingIdentityCard(
                cardKey: cardKey,
                name: 'Casa de Teste',
                visual: const ResolvedAccountProfileVisual(
                  typeLabel: 'Local',
                  typeVisual: ResolvedProfileTypeVisual.icon(
                    iconData: Icons.place,
                    backgroundColor: Colors.teal,
                    iconColor: Colors.white,
                  ),
                  surfaceImageUrl: null,
                  compactImageUrl: null,
                  identityAvatarUrl: null,
                  themeSeedColor: null,
                ),
                tags: tags,
              ),
            ),
          ),
        ),
      ),
    );

    for (final tag in tags) {
      expect(find.text(tag), findsOneWidget);
    }
    expect(tester.getSize(find.byKey(cardKey)).height, greaterThan(180));
  });
}
