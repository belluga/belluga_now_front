import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class ProfileActionButtonController {
  ProfileActionButtonController({
    AuthRepositoryContract? authRepository,
  }) : _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>();

  final AuthRepositoryContract _authRepository;

  String get userFirstName =>
      _authRepository.userStreamValue.value?.profile.nameValue?.firstName ?? '';
}
