import 'package:belluga_now/presentation/shared/visuals/resolved_account_profile_visual.dart';
import 'package:belluga_now/presentation/shared/visuals/resolved_profile_type_visual.dart';
import 'package:belluga_now/presentation/shared/widgets/account_profile_overlapping_identity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
