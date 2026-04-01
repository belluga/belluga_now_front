import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_custom_data.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:stream_value/core/stream_value.dart';

export 'package:belluga_now/domain/user/user_custom_data.dart';

typedef AuthRepositoryContractPrimString = String;
typedef AuthRepositoryContractPrimInt = int;
typedef AuthRepositoryContractPrimBool = bool;
typedef AuthRepositoryContractPrimDouble = double;
typedef AuthRepositoryContractPrimDateTime = DateTime;
typedef AuthRepositoryContractPrimDynamic = dynamic;
typedef AuthRepositoryContractParamString = AuthRepositoryContractTextValue;

abstract class AuthRepositoryContract<T extends UserContract> {
  Object get backend;

  final userStreamValue = StreamValue<T?>();

  T get user => userStreamValue.value!;

  String get userToken;

  void setUserToken(AuthRepositoryContractParamString? token);

  Future<String> getDeviceId();

  Future<String?> getUserId();

  AuthRepositoryContractPrimBool get isUserLoggedIn;

  AuthRepositoryContractPrimBool get isAuthorized;

  Future<void> init();

  Future<void> autoLogin();

  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  );

  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  );

  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  );

  Future<void> logout();

  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  );

  Future<void> sendPasswordResetEmail(AuthRepositoryContractParamString email);

  Future<void> updateUser(UserCustomData data);
}
