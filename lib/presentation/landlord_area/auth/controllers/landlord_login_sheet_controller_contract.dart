abstract class LandlordLoginSheetControllerContract {
  bool get hasValidSession;

  Future<void> loginWithEmailPassword(String email, String password);

  Future<void> enableAdminMode();

  Future<bool> enterAdminModeWithCredentials(String email, String password);

  Future<bool> ensureAdminMode();
}
