import 'package:flutter_laravel_backend_boilerplate/domain/user/user_contract.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AuthRepositoryContract<T extends UserContract> {
  final userStreamValue = StreamValue<T?>();

  T get user => userStreamValue.value!;

  bool get isUserLoggedIn;

  bool get isAuthorized;

  Future<void> init();

  Future<T?> loginWithEmailPassword(String email, String password);

  Future<void> signUpWithEmailPassword(String email, String password);

  Future<void> logout();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updateUser(Map<String, Object?> data);

}
