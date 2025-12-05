import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ProfileScreenController implements Disposable {
  ProfileScreenController({
    AuthRepositoryContract? authRepository,
    AppDataRepository? appDataRepository,
  })  : _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepository>();

  final AuthRepositoryContract _authRepository;
  final AppDataRepository _appDataRepository;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? _syncedUserId;

  StreamValue<UserContract?> get userStreamValue =>
      _authRepository.userStreamValue;

  StreamValue<ThemeMode?> get themeModeStreamValue =>
      _appDataRepository.themeModeStreamValue;
  ThemeMode get themeMode => _appDataRepository.themeMode;
  Future<void> setThemeMode(ThemeMode mode) =>
      _appDataRepository.setThemeMode(mode);

  void syncFromUser(UserContract? user) {
    if (user == null) return;
    final id = user.uuidValue.value.toString();
    if (id == _syncedUserId) return;
    _syncedUserId = id;
    nameController.text = user.profile.nameValue?.value ?? '';
    emailController.text = user.profile.emailValue?.value ?? '';
    // TODO(Delphi): Wire description and phone from user profile/custom data once available.
  }

  Future<void> requestAvatarUpdate() async {
    // TODO(Delphi): Implement avatar picker/upload.
    debugPrint('[Profile] Avatar update requested');
  }

  Future<void> saveProfile() async {
    // TODO(Delphi): Persist profile changes to backend.
    debugPrint(
      '[Profile] Save requested -> name=${nameController.text}, '
      'email=${emailController.text}, phone=${phoneController.text}, '
      'description=${descriptionController.text}',
    );
  }

  Future<void> logout() => _authRepository.logout();

  @override
  void onDispose() {
    nameController.dispose();
    descriptionController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }
}
