import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AuthRepositoryContract<T extends UserContract> {
  BackendContract get backend;

  final userStreamValue = StreamValue<T?>();

  T get user => userStreamValue.value!;

  String get userToken;

  void setUserToken(String? token);

  Future<String> getDeviceId();

  Future<String?> getUserId();

  bool get isUserLoggedIn;

  bool get isAuthorized;

  Future<void> init();

  Future<void> autoLogin();

  Future<void> loginWithEmailPassword(String email, String password);

  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  );

  Future<void> sendTokenRecoveryPassword(String email, String codigoEnviado);

  Future<void> logout();

  Future<void> createNewPassword(String newPassword, String confirmPassword);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updateUser(Map<String, Object?> data);
}
