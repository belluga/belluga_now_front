import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_relation_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders invite relation filters with discovery-style selection',
      (tester) async {
    String? selectedReason = 'friend';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InviteShareRelationFilterChips(
            selectedReason: selectedReason,
            availableReasons: const <String>[
              'contact_match',
              'favorite_by_you',
              'favorited_you',
              'friend',
            ],
            onSelectReason: (reason) {
              selectedReason = reason;
            },
          ),
        ),
      ),
    );

    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Contatos'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Favoritaram você'), findsOneWidget);
    expect(find.text('Amigos'), findsOneWidget);

    await tester.tap(find.text('Contatos'));

    expect(selectedReason, 'contact_match');
  });
}
