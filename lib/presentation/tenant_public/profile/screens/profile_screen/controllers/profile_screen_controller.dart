import 'dart:async';
import 'dart:io';

import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
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
    ProximityPreferencesRepositoryContract? proximityPreferencesRepository,
    ProfileAvatarStorageContract? avatarStorage,
  })  : _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _proximityPreferencesRepository = proximityPreferencesRepository ??
            (GetIt.I.isRegistered<ProximityPreferencesRepositoryContract>()
                ? GetIt.I.get<ProximityPreferencesRepositoryContract>()
                : null),
        _avatarStorage =
            avatarStorage ?? GetIt.I.get<ProfileAvatarStorageContract>() {
    _bindUserStream();
    _bindMaxRadiusStream();
    _bindProximityPreferenceStream();
  }

  final AuthRepositoryContract _authRepository;
  final AppDataRepositoryContract _appDataRepository;
  final ProximityPreferencesRepositoryContract? _proximityPreferencesRepository;
  final ProfileAvatarStorageContract _avatarStorage;
  StreamSubscription<UserContract?>? _userSubscription;
  StreamSubscription<DistanceInMetersValue>? _maxRadiusSubscription;
  StreamSubscription<ProximityPreference?>? _proximityPreferenceSubscription;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController editFieldController = TextEditingController();
  final TextEditingController radiusKmController = TextEditingController();
  final TextEditingController fixedOriginLatitudeController =
      TextEditingController();
  final TextEditingController fixedOriginLongitudeController =
      TextEditingController();
  final TextEditingController fixedOriginLabelController =
      TextEditingController();
  final StreamValue<String?> localAvatarPathStreamValue =
      StreamValue<String?>();
  final StreamValue<int> formVersionStreamValue =
      StreamValue<int>(defaultValue: 0);
  final StreamValue<double> maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: 50000);
  final StreamValue<bool> isUsingFixedOriginStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String> activeOriginSummaryStreamValue =
      StreamValue<String>(defaultValue: 'Localização atual');
  final StreamValue<String?> originPreferenceFeedbackStreamValue =
      StreamValue<String?>(defaultValue: null);

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
    maxRadiusMetersStreamValue
        .addValue(_appDataRepository.maxRadiusMeters.value);
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
      _proximityPreferencesRepository?.updateMaxDistanceMeters(
        _distanceInMetersValue(meters),
      ) ??
      _appDataRepository.setMaxRadiusMeters(_distanceInMetersValue(meters));

  void _bindProximityPreferenceStream() {
    final repository = _proximityPreferencesRepository;
    if (repository == null) {
      _applyProximityPreference(null);
      return;
    }

    _proximityPreferenceSubscription?.cancel();
    _proximityPreferenceSubscription =
        repository.proximityPreferenceStreamValue.stream.listen(
      _applyProximityPreference,
    );
    _applyProximityPreference(repository.proximityPreference);
  }

  void _applyProximityPreference(ProximityPreference? preference) {
    final effectivePreference = preference ??
        ProximityPreference(
          maxDistanceMetersValue: _appDataRepository.maxRadiusMeters,
          locationPreference:
              const ProximityLocationPreference.liveDeviceLocation(),
        );

    final fixedReference =
        effectivePreference.locationPreference.fixedReference;
    isUsingFixedOriginStreamValue.addValue(
      effectivePreference.locationPreference.usesFixedReference,
    );
    activeOriginSummaryStreamValue.addValue(
      _buildOriginSummary(effectivePreference),
    );

    if (fixedReference != null) {
      fixedOriginLatitudeController.text =
          fixedReference.coordinate.latitude.toStringAsFixed(6);
      fixedOriginLongitudeController.text =
          fixedReference.coordinate.longitude.toStringAsFixed(6);
      fixedOriginLabelController.text = fixedReference.label ?? '';
    } else {
      fixedOriginLatitudeController.clear();
      fixedOriginLongitudeController.clear();
      fixedOriginLabelController.clear();
    }
  }

  String? saveOriginPreference({
    required bool useFixedOrigin,
  }) {
    if (!useFixedOrigin) {
      originPreferenceFeedbackStreamValue.addValue(null);
      unawaited(
        _persistOriginPreference(() async {
          final repository = _proximityPreferencesRepository;
          if (repository != null) {
            await repository.setLiveDeviceLocation();
            return;
          }
          await _appDataRepository.useUserLiveLocationOrigin();
        }),
      );
      return null;
    }

    final validationError = _validateFixedOriginFields();
    if (validationError != null) {
      return validationError;
    }

    final fixedReference = _buildFixedReference();
    originPreferenceFeedbackStreamValue.addValue(null);
    unawaited(
      _persistOriginPreference(() async {
        final repository = _proximityPreferencesRepository;
        if (repository != null) {
          await repository.setFixedReference(
            fixedReference: fixedReference,
          );
          return;
        }
        await _appDataRepository.useUserFixedLocationOrigin(
          fixedLocationReference: fixedReference.coordinate,
        );
      }),
    );
    return null;
  }

  String? _validateFixedOriginFields() {
    final latitude = double.tryParse(fixedOriginLatitudeController.text.trim());
    if (latitude == null || latitude < -90 || latitude > 90) {
      return 'Latitude inválida.';
    }

    final longitude =
        double.tryParse(fixedOriginLongitudeController.text.trim());
    if (longitude == null || longitude < -180 || longitude > 180) {
      return 'Longitude inválida.';
    }

    return null;
  }

  FixedLocationReference _buildFixedReference() {
    final latitude = double.parse(fixedOriginLatitudeController.text.trim());
    final longitude = double.parse(fixedOriginLongitudeController.text.trim());

    return FixedLocationReference(
      sourceKind: FixedLocationReferenceSourceKind.manualCoordinate,
      coordinate: CityCoordinate(
        latitudeValue: LatitudeValue()..parse(latitude.toString()),
        longitudeValue: LongitudeValue()..parse(longitude.toString()),
      ),
      labelValue: _optionalTextValue(fixedOriginLabelController.text),
    );
  }

  Future<void> _persistOriginPreference(
    Future<void> Function() persist,
  ) async {
    try {
      await persist();
    } catch (_) {
      originPreferenceFeedbackStreamValue.addValue(
        'Nao foi possivel salvar a localizacao selecionada.',
      );
    }
  }

  ProximityPreferenceOptionalTextValue? _optionalTextValue(String raw) {
    final value = ProximityPreferenceOptionalTextValue.fromRaw(raw);
    return value.nullableValue == null ? null : value;
  }

  String _buildOriginSummary(ProximityPreference preference) {
    final fixedReference = preference.locationPreference.fixedReference;
    if (fixedReference == null) {
      return 'Localização atual';
    }

    final label = fixedReference.label?.trim();
    if (label != null && label.isNotEmpty) {
      return label;
    }

    return 'Lat ${fixedReference.coordinate.latitude.toStringAsFixed(6)}'
        ' · Lng ${fixedReference.coordinate.longitude.toStringAsFixed(6)}';
  }

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
    _proximityPreferenceSubscription?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    emailController.dispose();
    phoneController.dispose();
    editFieldController.dispose();
    radiusKmController.dispose();
    fixedOriginLatitudeController.dispose();
    fixedOriginLongitudeController.dispose();
    fixedOriginLabelController.dispose();
    localAvatarPathStreamValue.dispose();
    formVersionStreamValue.dispose();
    maxRadiusMetersStreamValue.dispose();
    isUsingFixedOriginStreamValue.dispose();
    activeOriginSummaryStreamValue.dispose();
    originPreferenceFeedbackStreamValue.dispose();
  }
}
