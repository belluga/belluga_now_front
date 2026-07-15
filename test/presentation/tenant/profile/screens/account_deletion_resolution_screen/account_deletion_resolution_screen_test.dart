import 'dart:async';

import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/account_deletion_resolution_screen/account_deletion_resolution_screen.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/account_deletion_resolution_screen/controllers/account_deletion_resolution_controller.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/account_deletion_resolution_screen/controllers/account_deletion_resolution_ui_phase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'confirmed deletion is non-returnable and keeps exit inside the terminal boundary',
    (tester) async {
      final authRepository = _FakeAuthRepository()
        ..setJourney(AccountDeletionJourneyPhase.confirmed);
      final controller = AccountDeletionResolutionController(
        authRepository: authRepository,
      );
      GetIt.I.registerSingleton<AccountDeletionResolutionController>(
        controller,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: const AccountDeletionResolutionScreen(),
        ),
      );

      final popScope = tester.widget<PopScope<dynamic>>(
        find.byWidgetPredicate((widget) => widget is PopScope),
      );
      expect(popScope.canPop, isFalse);
      expect(find.text('Conta removida'), findsOneWidget);
      expect(
        find.byKey(const Key('accountDeletionContinueAnonymousButton')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('accountDeletionExitAppButton')));
      await tester.pump();

      expect(
        find.text('Você pode fechar o app pelo sistema quando quiser.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('unknown outcome offers reconciliation without a false claim', (
    tester,
  ) async {
    final authRepository = _FakeAuthRepository()
      ..setJourney(AccountDeletionJourneyPhase.unknown);
    final controller = AccountDeletionResolutionController(
      authRepository: authRepository,
    );
    GetIt.I.registerSingleton<AccountDeletionResolutionController>(controller);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: const AccountDeletionResolutionScreen(),
      ),
    );

    expect(find.text('Não foi possível confirmar a remoção'), findsOneWidget);
    expect(
      find.byKey(const Key('accountDeletionContinueAnonymousButton')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('accountDeletionReconcileButton')));
    await tester.pumpAndSettle();

    expect(authRepository.reconcileCallCount, 1);
    expect(find.text('Conta removida'), findsOneWidget);
  });

  test(
    'continuation drops twenty concurrent presses until its first result',
    () async {
      final continuationCompleter =
          Completer<AccountDeletionContinuationOutcome>();
      final authRepository = _FakeAuthRepository(
        continuationCompleter: continuationCompleter,
      )..setJourney(AccountDeletionJourneyPhase.confirmed);
      final controller = AccountDeletionResolutionController(
        authRepository: authRepository,
      );
      addTearDown(controller.onDispose);

      final requests = List<Future<void>>.generate(
        20,
        (_) => controller.continueAnonymously(),
      );

      expect(authRepository.continueCallCount, 1);
      expect(
        controller.uiPhaseStreamValue.value,
        AccountDeletionResolutionUiPhase.continuing,
      );

      continuationCompleter.complete(AccountDeletionContinuationOutcome.failed);
      await Future.wait(requests);

      expect(
        controller.uiPhaseStreamValue.value,
        AccountDeletionResolutionUiPhase.continuationFailed,
      );
    },
  );
}

class _FakeAuthRepository extends AuthRepositoryContract {
  _FakeAuthRepository({this.continuationCompleter});

  final Completer<AccountDeletionContinuationOutcome>? continuationCompleter;
  int reconcileCallCount = 0;
  int continueCallCount = 0;

  @override
  Object get backend => Object();

  void setJourney(AccountDeletionJourneyPhase phase) {
    accountDeletionJourneyStreamValue.addValue(
      AccountDeletionJourneyState(phase),
    );
  }

  @override
  Future<void> reconcileUnknownAccountDeletion() async {
    reconcileCallCount += 1;
    setJourney(AccountDeletionJourneyPhase.confirmed);
  }

  @override
  Future<AccountDeletionContinuationOutcome>
  continueAnonymouslyAfterConfirmedAccountDeletion() {
    continueCallCount += 1;
    return continuationCompleter?.future ??
        Future.value(AccountDeletionContinuationOutcome.unavailable);
  }

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => false;

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}
