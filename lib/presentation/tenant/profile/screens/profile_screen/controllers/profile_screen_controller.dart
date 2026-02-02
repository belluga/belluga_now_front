import 'dart:io';

import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:belluga_now/presentation/landlord/auth/controllers/landlord_login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stream_value/core/stream_value.dart';

class ProfileScreenController implements Disposable {
  ProfileScreenController({
    AuthRepositoryContract? authRepository,
    AppDataRepositoryContract? appDataRepository,
    AdminModeRepositoryContract? adminModeRepository,
    LandlordLoginController? landlordLoginController,
    ProfileAvatarStorageContract? avatarStorage,
  })  : _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _adminModeRepository =
            adminModeRepository ?? GetIt.I.get<AdminModeRepositoryContract>(),
        _landlordLoginController =
            landlordLoginController ?? GetIt.I.get<LandlordLoginController>(),
        _avatarStorage =
            avatarStorage ?? GetIt.I.get<ProfileAvatarStorageContract>();

  final AuthRepositoryContract _authRepository;
  final AppDataRepositoryContract _appDataRepository;
  final AdminModeRepositoryContract _adminModeRepository;
  final LandlordLoginController _landlordLoginController;
  final ProfileAvatarStorageContract _avatarStorage;

  LandlordLoginController get landlordLoginController =>
      _landlordLoginController;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final StreamValue<String?> localAvatarPathStreamValue =
      StreamValue<String?>();
  final StreamValue<int> formVersionStreamValue =
      StreamValue<int>(defaultValue: 0);
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _appDataRepository.maxRadiusMetersStreamValue;

  String? _syncedUserId;
  String _initialName = '';
  String _initialEmail = '';
  String _initialDescription = '';
  String _initialPhone = '';

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
    _initialName = user.profile.nameValue?.value ?? '';
    _initialEmail = user.profile.emailValue?.value ?? '';
    _initialDescription = '';
    _initialPhone = '';
    nameController.text = _initialName;
    emailController.text = _initialEmail;
    // TODO(Delphi): Wire description and phone from user profile/custom data once available.
  }

  Future<void> loadAvatarPath() async {
    final stored = await _avatarStorage.readAvatarPath();
    if (stored == null || stored.trim().isEmpty) {
      localAvatarPathStreamValue.addValue(null);
      return;
    }
    final file = File(stored);
    if (!await file.exists()) {
      await _avatarStorage.clearAvatarPath();
      localAvatarPathStreamValue.addValue(null);
      return;
    }
    localAvatarPathStreamValue.addValue(stored);
  }

  bool get hasPendingChanges {
    return nameController.text.trim() != _initialName.trim() ||
        emailController.text.trim() != _initialEmail.trim() ||
        descriptionController.text.trim() != _initialDescription.trim() ||
        phoneController.text.trim() != _initialPhone.trim();
  }

  void bumpFormVersion() {
    formVersionStreamValue.addValue(formVersionStreamValue.value + 1);
  }

  Future<void> setMaxRadiusMeters(double meters) =>
      _appDataRepository.setMaxRadiusMeters(meters);

  Future<void> requestAvatarUpdate() async {
    debugPrint('[Profile] Avatar update requested');
  }

  Future<void> pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final extension = picked.path.split('.').last;
    final fileName =
        'avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final targetPath = '${directory.path}/$fileName';
    final saved = await File(picked.path).copy(targetPath);

    final previousPath = localAvatarPathStreamValue.value;
    if (previousPath != null && previousPath.isNotEmpty) {
      final previousFile = File(previousPath);
      if (await previousFile.exists()) {
        await previousFile.delete();
      }
    }

    await _avatarStorage.writeAvatarPath(saved.path);
    localAvatarPathStreamValue.addValue(saved.path);
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

  Future<void> switchToUserMode() => _adminModeRepository.setUserMode();

  Future<bool> ensureAdminMode() => _landlordLoginController.ensureAdminMode();

  @override
  void onDispose() {
    nameController.dispose();
    descriptionController.dispose();
    emailController.dispose();
    phoneController.dispose();
    localAvatarPathStreamValue.dispose();
    formVersionStreamValue.dispose();
  }
}
