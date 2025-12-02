import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ProfileScreenController {
  ProfileScreenController({
    AuthRepositoryContract? authRepository,
  }) : _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>();

  final AuthRepositoryContract _authRepository;

  StreamValue<UserContract?> get userStreamValue =>
      _authRepository.userStreamValue;

  Future<void> logout() => _authRepository.logout();
}
