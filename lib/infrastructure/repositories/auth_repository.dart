import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/user_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/main.dart';

final class AuthRepository extends AuthRepositoryContract<UserBelluga> {
  AuthRepository() {
    _userTokenStreamValue.stream.listen(_onUpdateUserTokenOnLocalStorage);
  }

  @override
  BackendContract get backend => GetIt.I.get<BackendContract>();

  @override
  String get userToken => _userTokenStreamValue.value!;

  final StreamValue<String?> _userTokenStreamValue = StreamValue<String?>();

  static FlutterSecureStorage get storage => FlutterSecureStorage();

  void userTokenUpdate(String token) => _userTokenStreamValue.addValue(token);
  void userTokenDelete() => _userTokenStreamValue.addValue(null);

  @override
  bool get isUserLoggedIn {
    return userStreamValue.value != null;
  }

  @override
  bool get isAuthorized {
    return userStreamValue.value != null;
  }

  @override
  Future<void> init() async {
    await _getUserTokenFromLocalStorage();
    await autoLogin();
  }

  @override
  Future<void> autoLogin() async {
    final token = await storage.read(key: "user_token");

    if (token == null) {
      return;
    }

    userTokenUpdate(token);

    final user = await backend.auth.loginCheck();

    userStreamValue.addValue(UserBelluga.fromDTO(user));

    return Future.value();
  }

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {
    var (UserDTO _user, String _token) =
        await backend.auth.loginWithEmailPassword(
      email,
      password,
    );

    _userTokenStreamValue.addValue(_token);
    userStreamValue.addValue(UserBelluga.fromDTO(_user));

    return Future.value();
  }

  @override
  Future<void> logout() async {
    await backend.auth.logout();

    userStreamValue.addValue(null);
    _userTokenStreamValue.addValue(null);

    return Future.value();
  }

  @override
  Future<void> signUpWithEmailPassword(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(Map<String, Object?> data) {
    throw UnimplementedError();
  }

  Future<void> _onUpdateUserTokenOnLocalStorage(String? token) async {
    if (token == null) {
      await _deleteUserTokenOnLocalStorage();
      return;
    }

    _saveUserTokenOnLocalStorage(token);
  }

  Future<void> _deleteUserTokenOnLocalStorage() async {
    await AuthRepository.storage.delete(key: "user_token");
  }

  Future<void> _saveUserTokenOnLocalStorage(String token) async {
    await AuthRepository.storage.write(key: "user_token", value: token);
  }

  Future<void> _getUserTokenFromLocalStorage() async {
    final token = await AuthRepository.storage.read(key: "user_token");
    _userTokenStreamValue.addValue(token);
  }

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> createNewPassword(String newPassword, String confirmPassword) {
    throw UnimplementedError();
  }
}
