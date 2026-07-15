import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/account_deletion_resolution_screen/controllers/account_deletion_resolution_ui_phase.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class AccountDeletionResolutionController implements Disposable {
  AccountDeletionResolutionController({AuthRepositoryContract? authRepository})
    : _authRepository = authRepository ?? GetIt.I.get<AuthRepositoryContract>();

  final AuthRepositoryContract _authRepository;
  final StreamValue<AccountDeletionResolutionUiPhase> uiPhaseStreamValue =
      StreamValue<AccountDeletionResolutionUiPhase>(
        defaultValue: AccountDeletionResolutionUiPhase.idle,
      );
  final StreamValue<int> tenantPublicNavigationRequestStreamValue =
      StreamValue<int>(defaultValue: 0);

  StreamValue<AccountDeletionJourneyState> get journeyStreamValue =>
      _authRepository.accountDeletionJourneyStreamValue;

  Future<void>? _reconciliationInFlight;
  Future<void>? _continuationInFlight;

  Future<void> reconcileUnknownOutcome() {
    final inFlight = _reconciliationInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    uiPhaseStreamValue.addValue(AccountDeletionResolutionUiPhase.reconciling);
    final action = _authRepository
        .reconcileUnknownAccountDeletion()
        .whenComplete(() {
          _reconciliationInFlight = null;
          if (uiPhaseStreamValue.value ==
              AccountDeletionResolutionUiPhase.reconciling) {
            uiPhaseStreamValue.addValue(AccountDeletionResolutionUiPhase.idle);
          }
        });
    _reconciliationInFlight = action;
    return action;
  }

  Future<void> continueAnonymously() {
    final inFlight = _continuationInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    uiPhaseStreamValue.addValue(AccountDeletionResolutionUiPhase.continuing);
    final action = _continueAnonymouslyOnce().whenComplete(() {
      _continuationInFlight = null;
    });
    _continuationInFlight = action;
    return action;
  }

  Future<void> _continueAnonymouslyOnce() async {
    final outcome = await _authRepository
        .continueAnonymouslyAfterConfirmedAccountDeletion();
    if (outcome == AccountDeletionContinuationOutcome.continued) {
      uiPhaseStreamValue.addValue(AccountDeletionResolutionUiPhase.idle);
      tenantPublicNavigationRequestStreamValue.addValue(
        tenantPublicNavigationRequestStreamValue.value + 1,
      );
      return;
    }

    uiPhaseStreamValue.addValue(
      AccountDeletionResolutionUiPhase.continuationFailed,
    );
  }

  void showExitGuidance() {
    uiPhaseStreamValue.addValue(AccountDeletionResolutionUiPhase.exitGuidance);
  }

  @override
  void onDispose() {
    uiPhaseStreamValue.dispose();
    tenantPublicNavigationRequestStreamValue.dispose();
  }
}
