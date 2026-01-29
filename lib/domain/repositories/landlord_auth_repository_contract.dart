abstract class LandlordAuthRepositoryContract {
  bool get hasValidSession;

  String get token;

  Future<void> init();

  Future<void> loginWithEmailPassword(String email, String password);

  Future<void> logout();
}
