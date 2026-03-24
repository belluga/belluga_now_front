import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:stream_value/core/stream_value.dart';

typedef AuthRepositoryContractPrimString = String;
typedef AuthRepositoryContractPrimInt = int;
typedef AuthRepositoryContractPrimBool = bool;
typedef AuthRepositoryContractPrimDouble = double;
typedef AuthRepositoryContractPrimDateTime = DateTime;
typedef AuthRepositoryContractPrimDynamic = dynamic;

abstract class AuthRepositoryContract<T extends UserContract> {
  Object get backend;

  final userStreamValue = StreamValue<T?>();

  T get user => userStreamValue.value!;

  AuthRepositoryContractPrimString get userToken;

  void setUserToken(AuthRepositoryContractPrimString? token);

  Future<AuthRepositoryContractPrimString> getDeviceId();

  Future<AuthRepositoryContractPrimString?> getUserId();

  AuthRepositoryContractPrimBool get isUserLoggedIn;

  AuthRepositoryContractPrimBool get isAuthorized;

  Future<void> init();

  Future<void> autoLogin();

  Future<void> loginWithEmailPassword(AuthRepositoryContractPrimString email,
      AuthRepositoryContractPrimString password);

  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractPrimString name,
    AuthRepositoryContractPrimString email,
    AuthRepositoryContractPrimString password,
  );

  Future<void> sendTokenRecoveryPassword(AuthRepositoryContractPrimString email,
      AuthRepositoryContractPrimString codigoEnviado);

  Future<void> logout();

  Future<void> createNewPassword(AuthRepositoryContractPrimString newPassword,
      AuthRepositoryContractPrimString confirmPassword);

  Future<void> sendPasswordResetEmail(AuthRepositoryContractPrimString email);

  Future<void> updateUser(Map<AuthRepositoryContractPrimString, Object?> data);
}
