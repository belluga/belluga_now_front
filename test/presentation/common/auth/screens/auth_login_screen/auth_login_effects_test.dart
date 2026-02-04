import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/widgets/auth_login_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows snackbar and clears general error', (tester) async {
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AuthLoginEffects(
          generalError: 'Erro desconhecido',
          loginResult: null,
          signUpResult: null,
          onClearGeneralError: () => cleared = true,
          onClearLoginResult: () {},
          onClearSignUpResult: () {},
          child: const Scaffold(
            body: Text('Body'),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Erro desconhecido'), findsOneWidget);
    expect(cleared, isTrue);
  });
}
