import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/invite_status_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpIcon(
    WidgetTester tester, {
    required bool isConfirmed,
    required int pendingInvitesCount,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InviteStatusIcon(
            isConfirmed: isConfirmed,
            pendingInvitesCount: pendingInvitesCount,
          ),
        ),
      ),
    );
  }

  testWidgets('confirmed status uses appointment glyph', (tester) async {
    await pumpIcon(
      tester,
      isConfirmed: true,
      pendingInvitesCount: 0,
    );

    expect(find.byIcon(BooraIcons.confirmedAttendance), findsOneWidget);
    expect(find.byIcon(BooraIcons.inviteOutlined), findsNothing);
  });

  testWidgets('pending invite status uses outlined invitation glyph', (
    tester,
  ) async {
    await pumpIcon(
      tester,
      isConfirmed: false,
      pendingInvitesCount: 1,
    );

    expect(find.byIcon(BooraIcons.inviteOutlined), findsOneWidget);
    expect(find.byIcon(BooraIcons.confirmedAttendance), findsNothing);
  });

  testWidgets('no confirmation and no invites hides the icon', (tester) async {
    await pumpIcon(
      tester,
      isConfirmed: false,
      pendingInvitesCount: 0,
    );

    expect(find.byType(SizedBox), findsOneWidget);
    expect(find.byIcon(BooraIcons.inviteOutlined), findsNothing);
    expect(find.byIcon(BooraIcons.confirmedAttendance), findsNothing);
  });
}
