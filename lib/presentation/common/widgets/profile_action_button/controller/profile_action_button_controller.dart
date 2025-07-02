import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:get_it/get_it.dart';

class ProfileActionButtonController {
  final _authRepository = GetIt.I.get<AuthRepositoryContract>();

  String get userFirstName =>
      _authRepository.userStreamValue.value?.profile.nameValue?.firstName ?? '';
}
