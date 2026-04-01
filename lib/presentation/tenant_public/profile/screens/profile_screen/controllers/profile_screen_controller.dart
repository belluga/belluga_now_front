import 'dart:async';
import 'dart:io';

import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:belluga_now/domain/user/value_objects/profile_avatar_path_value.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stream_value/core/stream_value.dart';

class ProfileScreenController implements Disposable {
  ProfileScreenController({
    AuthRepositoryContract? authRepository,
    AppDataRepositoryContract? appDataRepository,
    ProfileAvatarStorageContract? avatarStorage,
  })  : _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _avatarStorage =
            avatarStorage ?? GetIt.I.get<ProfileAvatarStorageContract>() {
    _bindUserStream();
    _bindMaxRadiusStream();
  }

  final AuthRepositoryContract _authRepository;
  final AppDataRepositoryContract _appDataRepository;
  final ProfileAvatarStorageContract _avatarStorage;
  StreamSubscription<UserContract?>? _userSubscription;
  StreamSubscription<DistanceInMetersValue>? _maxRadiusSubscription;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController editFieldController = TextEditingController();
  final TextEditingController radiusKmController = TextEditingController();
  final StreamValue<String?> localAvatarPathStreamValue =
      StreamValue<String?>();
  final StreamValue<int> formVersionStreamValue =
      StreamValue<int>(defaultValue: 0);
  final StreamValue<double> maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: 50000);

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
      _appDataRepository.setThemeMode(AppThemeModeValue.fromRaw(mode));

  bool syncFromUser(UserContract? user) {
    if (user == null) return false;
    final id = user.uuidValue.value.toString();
    if (id == _syncedUserId) return false;
    _syncedUserId = id;
    _initialName = user.profile.nameValue?.value ?? '';
    _initialEmail = user.profile.emailValue?.value ?? '';
    _initialDescription = '';
    _initialPhone = '';
    nameController.text = _initialName;
    emailController.text = _initialEmail;
    // TODO(Delphi): Wire description and phone from user profile/custom data once available.
    return true;
  }

  void _bindUserStream() {
    _userSubscription?.cancel();
    _userSubscription = userStreamValue.stream.listen((user) {
      if (syncFromUser(user)) {
        bumpFormVersion();
      }
    });
    if (syncFromUser(userStreamValue.value)) {
      bumpFormVersion();
    }
  }

  void _bindMaxRadiusStream() {
    _maxRadiusSubscription?.cancel();
    maxRadiusMetersStreamValue.addValue(_appDataRepository.maxRadiusMeters.value);
    _maxRadiusSubscription =
        _appDataRepository.maxRadiusMetersStreamValue.stream.listen((value) {
      maxRadiusMetersStreamValue.addValue(value.value);
    });
  }

  Future<void> loadAvatarPath() async {
    final stored = await _avatarStorage.readAvatarPath();
    final storedPath = stored?.value.trim();
    if (storedPath == null || storedPath.isEmpty) {
      localAvatarPathStreamValue.addValue(null);
      return;
    }
    final file = File(storedPath);
    if (!await file.exists()) {
      await _avatarStorage.clearAvatarPath();
      localAvatarPathStreamValue.addValue(null);
      return;
    }
    localAvatarPathStreamValue.addValue(storedPath);
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
      _appDataRepository.setMaxRadiusMeters(_distanceInMetersValue(meters));

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

    await _avatarStorage.writeAvatarPath(_profileAvatarPathValue(saved.path));
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

  DistanceInMetersValue _distanceInMetersValue(double raw) {
    final value = DistanceInMetersValue();
    value.parse(raw.toString());
    return value;
  }

  ProfileAvatarPathValue _profileAvatarPathValue(String raw) {
    final value = ProfileAvatarPathValue();
    value.parse(raw);
    return value;
  }

  @override
  void onDispose() {
    _userSubscription?.cancel();
    _maxRadiusSubscription?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    emailController.dispose();
    phoneController.dispose();
    editFieldController.dispose();
    radiusKmController.dispose();
    localAvatarPathStreamValue.dispose();
    formVersionStreamValue.dispose();
    maxRadiusMetersStreamValue.dispose();
  }
}
