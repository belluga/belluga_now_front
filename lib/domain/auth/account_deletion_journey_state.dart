/// Process-local safety state for the current-account permanent deletion flow.
///
/// This state is intentionally neither persisted nor transported. It prevents a
/// lost destructive response from being collapsed into ordinary anonymous
/// bootstrap while the app process is still alive.
enum AccountDeletionJourneyPhase {
  idle,
  deleting,
  preEraseRejected,
  unknown,
  confirmed,
  continuing,
}

class AccountDeletionJourneyState {
  const AccountDeletionJourneyState(this.phase);

  const AccountDeletionJourneyState.idle()
    : phase = AccountDeletionJourneyPhase.idle;

  final AccountDeletionJourneyPhase phase;

  bool get blocksAutomaticIdentityBootstrap =>
      phase == AccountDeletionJourneyPhase.deleting ||
      phase == AccountDeletionJourneyPhase.unknown ||
      phase == AccountDeletionJourneyPhase.confirmed ||
      phase == AccountDeletionJourneyPhase.continuing;

  bool get mayRenderResolutionBoundary =>
      phase == AccountDeletionJourneyPhase.unknown ||
      phase == AccountDeletionJourneyPhase.confirmed;

  bool get mayContinueAnonymously =>
      phase == AccountDeletionJourneyPhase.confirmed;
}

enum AccountDeletionDispatchOutcome { confirmed, preEraseRejected, unknown }

enum AccountDeletionContinuationOutcome { continued, unavailable, failed }
