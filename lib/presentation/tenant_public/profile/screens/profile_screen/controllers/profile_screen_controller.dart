import 'dart:async';
import 'dart:io';

import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/domain/repositories/self_profile_repository_contract.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:belluga_now/domain/user/self_profile.dart';
import 'package:belluga_now/domain/user/user_profile_media_upload.dart';
import 'package:belluga_now/domain/user/value_objects/user_profile_media_bytes_value.dart';
import 'package:belluga_now/domain/user/value_objects/profile_avatar_path_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ProfileScreenController implements Disposable {
  ProfileScreenController({
    AuthRepositoryContract? authRepository,
    AppDataRepositoryContract? appDataRepository,
    ProximityPreferencesRepositoryContract? proximityPreferencesRepository,
    ProfileAvatarStorageContract? avatarStorage,
    SelfProfileRepositoryContract? selfProfileRepository,
    InvitesRepositoryContract? invitesRepository,
  })  : _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>(),
        _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _proximityPreferencesRepository = proximityPreferencesRepository ??
            (GetIt.I.isRegistered<ProximityPreferencesRepositoryContract>()
                ? GetIt.I.get<ProximityPreferencesRepositoryContract>()
                : null),
        _avatarStorage =
            avatarStorage ?? GetIt.I.get<ProfileAvatarStorageContract>(),
        _selfProfileRepository = selfProfileRepository ??
            GetIt.I.get<SelfProfileRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>() {
    _bindUserStream();
    _bindSelfProfileStream();
    _bindMaxRadiusStream();
    _bindProximityPreferenceStream();
  }

  final AuthRepositoryContract _authRepository;
  final AppDataRepositoryContract _appDataRepository;
  final ProximityPreferencesRepositoryContract? _proximityPreferencesRepository;
  final ProfileAvatarStorageContract _avatarStorage;
  final SelfProfileRepositoryContract _selfProfileRepository;
  final InvitesRepositoryContract _invitesRepository;
  StreamSubscription<UserContract?>? _userSubscription;
  StreamSubscription<SelfProfile?>? _selfProfileSubscription;
  StreamSubscription<DistanceInMetersValue>? _maxRadiusSubscription;
  StreamSubscription<ProximityPreference?>? _proximityPreferenceSubscription;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
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
  final StreamValue<bool> isProfileLoadingStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isMatchedPeopleLoadingStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<List<InviteableRecipient>> matchedPeopleStreamValue =
      StreamValue<List<InviteableRecipient>>(defaultValue: const []);
  final StreamValue<String> matchedPeopleErrorStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<int> pendingInvitesCountStreamValue =
      StreamValue<int>(defaultValue: 0);
  final StreamValue<int> confirmedEventsCountStreamValue =
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
  String _initialDescription = '';
  SelfProfile? _currentProfile;
  UserProfileMediaUpload? _pendingAvatarUpload;
  bool _didInit = false;

  StreamValue<UserContract?> get userStreamValue =>
      _authRepository.userStreamValue;
  StreamValue<SelfProfile?> get currentProfileStreamValue =>
      _selfProfileRepository.currentProfileStreamValue;

  StreamValue<ThemeMode?> get themeModeStreamValue =>
      _appDataRepository.themeModeStreamValue;
  ThemeMode get themeMode => _appDataRepository.themeMode;
  Future<void> setThemeMode(ThemeMode mode) =>
      _appDataRepository.setThemeMode(AppThemeModeValue.fromRaw(mode));
  String? get currentAvatarUrl => _currentProfile?.avatarUrl;

  bool syncFromUser(UserContract? user) {
    if (user == null) return false;
    final id = user.uuidValue.value.toString();
    if (id == _syncedUserId) return false;
    _syncedUserId = id;
    return true;
  }

  Future<void> init() async {
    _didInit = true;
    await loadAvatarPath();
    final hasCachedProfile = currentProfileStreamValue.value != null ||
        _currentProfile != null;
    if (hasCachedProfile) {
      isProfileLoadingStreamValue.addValue(false);
      unawaited(refreshProfile(silent: true));
      return;
    }
    await refreshProfile();
  }

  void _bindUserStream() {
    _userSubscription?.cancel();
    _userSubscription = userStreamValue.stream.listen((user) {
      if (syncFromUser(user)) {
        if (_didInit) {
          final hasCachedProfile = currentProfileStreamValue.value != null ||
              _currentProfile != null;
          unawaited(refreshProfile(silent: hasCachedProfile));
        }
        bumpFormVersion();
      }
    });
    if (syncFromUser(userStreamValue.value)) {
      bumpFormVersion();
    }
  }

  void _bindSelfProfileStream() {
    _selfProfileSubscription?.cancel();
    _selfProfileSubscription = currentProfileStreamValue.stream.listen((profile) {
      if (profile == null) {
        return;
      }
      _applySelfProfile(profile);
      isProfileLoadingStreamValue.addValue(false);
    });

    final currentProfile = currentProfileStreamValue.value;
    if (currentProfile != null) {
      _applySelfProfile(currentProfile);
      isProfileLoadingStreamValue.addValue(false);
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
      await _clearStoredAvatarPathBestEffort(
        context: 'load-avatar-path missing-file cleanup',
        clearLocalPreview: true,
      );
      return;
    }
    localAvatarPathStreamValue.addValue(storedPath);
  }

  bool get hasPendingChanges {
    return nameController.text.trim() != _initialName.trim() ||
        descriptionController.text.trim() != _initialDescription.trim() ||
        _pendingAvatarUpload != null;
  }

  void bumpFormVersion() {
    formVersionStreamValue.addValue(formVersionStreamValue.value + 1);
  }

  Future<void> setMaxRadiusMeters(double meters) =>
      _proximityPreferencesRepository?.updateMaxDistanceMeters(
        _distanceInMetersValue(meters.clamp(1000, 50000).toDouble()),
      ) ??
      _appDataRepository.setMaxRadiusMeters(
        _distanceInMetersValue(meters.clamp(1000, 50000).toDouble()),
      );

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

  Future<void> refreshProfile({
    bool silent = false,
  }) async {
    if (!silent) {
      isProfileLoadingStreamValue.addValue(true);
    }
    try {
      await _selfProfileRepository.refreshCurrentProfile();
    } finally {
      isProfileLoadingStreamValue.addValue(false);
    }
  }

  Future<void> refreshMatchedPeople() async {
    isMatchedPeopleLoadingStreamValue.addValue(true);
    matchedPeopleErrorStreamValue.addValue('');
    try {
      final profile = _currentProfile;
      if (profile == null) {
        matchedPeopleStreamValue.addValue(const []);
        return;
      }
      _applySelfProfile(profile);
      await _invitesRepository.refreshInviteableRecipients();
      final recipients =
          _invitesRepository.inviteableRecipientsStreamValue.value ??
              const <InviteableRecipient>[];
      final filtered = recipients.where((recipient) {
        final userId = recipient.userId.trim();
        final profileId = recipient.receiverAccountProfileId.trim();
        if (userId.isNotEmpty && userId == profile.userId.trim()) {
          return false;
        }
        if (profile.accountProfileId.trim().isNotEmpty &&
            profileId == profile.accountProfileId.trim()) {
          return false;
        }
        return true;
      }).toList(growable: false);
      matchedPeopleStreamValue.addValue(filtered);
    } catch (error) {
      matchedPeopleErrorStreamValue.addValue(error.toString());
      matchedPeopleStreamValue.addValue(const []);
    } finally {
      isMatchedPeopleLoadingStreamValue.addValue(false);
    }
  }

  void _applySelfProfile(SelfProfile profile) {
    _currentProfile = profile;
    _syncedUserId =
        profile.userId.trim().isEmpty ? _syncedUserId : profile.userId;
    final resolvedDisplayName = _resolveEditableDisplayName(profile);
    _initialName = resolvedDisplayName;
    _initialDescription = profile.bio;
    nameController.text = resolvedDisplayName;
    descriptionController.text = profile.bio;
    phoneController.text = profile.phone;
    pendingInvitesCountStreamValue.addValue(profile.pendingInvitesCount);
    confirmedEventsCountStreamValue.addValue(profile.confirmedEventsCount);
    bumpFormVersion();
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
    final previousPendingAvatarUpload = _pendingAvatarUpload;
    await _avatarStorage.writeAvatarPath(_profileAvatarPathValue(saved.path));
    localAvatarPathStreamValue.addValue(saved.path);
    _pendingAvatarUpload = UserProfileMediaUpload(
      bytesValue: UserProfileMediaBytesValue()..set(await saved.readAsBytes()),
      fileNameValue: GenericStringValue(
        defaultValue: '',
        isRequired: true,
      )..parse(_fileNameFromPath(saved.path)),
      mimeTypeValue: GenericStringValue(
        defaultValue: '',
        isRequired: false,
      )..parse(_inferImageMimeType(saved.path) ?? ''),
    );
    bumpFormVersion();
    try {
      await saveProfile();
      if (previousPath != null &&
          previousPath.isNotEmpty &&
          previousPath != saved.path) {
        await _deleteFileBestEffort(
          File(previousPath),
          context: 'avatar-update previous-file cleanup',
        );
      }
      await _deleteFileBestEffort(
        saved,
        context: 'avatar-update staged-file cleanup',
      );
    } catch (error) {
      _pendingAvatarUpload = previousPendingAvatarUpload;
      if (previousPath != null && previousPath.isNotEmpty) {
        await _avatarStorage.writeAvatarPath(
          _profileAvatarPathValue(previousPath),
        );
        localAvatarPathStreamValue.addValue(previousPath);
      } else {
        await _clearStoredAvatarPathBestEffort(
          context: 'avatar-update rollback cleanup',
          clearLocalPreview: true,
        );
      }
      await _deleteFileBestEffort(
        saved,
        context: 'avatar-update rollback staged-file cleanup',
      );
      rethrow;
    }
  }

  Future<void> saveProfile() async {
    final trimmedName = nameController.text.trim();
    final trimmedDescription = descriptionController.text.trim();
    final hasNameChange = trimmedName != _initialName.trim();
    final hasDescriptionChange =
        trimmedDescription != _initialDescription.trim();
    final hasAvatarChange = _pendingAvatarUpload != null;

    if (!hasNameChange && !hasDescriptionChange && !hasAvatarChange) {
      return;
    }
    try {
      final updated = await _selfProfileRepository.updateCurrentProfile(
        displayNameValue: hasNameChange
            ? (UserDisplayNameValue(
                isRequired: false,
                minLenght: null,
              )..parse(trimmedName))
            : null,
        bioValue: hasDescriptionChange
            ? (DescriptionValue(
                defaultValue: '',
                minLenght: null,
              )..parse(trimmedDescription))
            : null,
        avatarUpload: _pendingAvatarUpload,
      );
      _pendingAvatarUpload = null;
      if (updated.userId.trim().isNotEmpty) {
        _syncedUserId = updated.userId;
      }
      await _clearStoredAvatarPathBestEffort(
        context: 'profile-save post-success cleanup',
        clearLocalPreview: true,
      );
    } catch (error, stackTrace) {
      debugPrint('ProfileScreenController.saveProfile failed');
      debugPrintStack(stackTrace: stackTrace);
      throw StateError(
        'Nao foi possivel salvar o perfil agora. Tente novamente.',
      );
    }
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

  void setFixedOriginCoordinate({
    required double latitude,
    required double longitude,
  }) {
    fixedOriginLatitudeController.text = latitude.toStringAsFixed(6);
    fixedOriginLongitudeController.text = longitude.toStringAsFixed(6);
  }

  String _fileNameFromPath(String path) {
    final normalized = path.trim();
    if (normalized.isEmpty) {
      return 'avatar-upload';
    }
    return normalized.split(RegExp(r'[\\/]')).last;
  }

  String? _inferImageMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return null;
  }

  Future<void> _clearStoredAvatarPathBestEffort({
    required String context,
    bool clearLocalPreview = false,
  }) async {
    try {
      await _avatarStorage.clearAvatarPath();
    } catch (error) {
      debugPrint(
        '[Profile] Ignoring avatar storage cleanup failure during $context: $error',
      );
    } finally {
      if (clearLocalPreview) {
        localAvatarPathStreamValue.addValue(null);
      }
    }
  }

  Future<void> _deleteFileBestEffort(
    File file, {
    required String context,
  }) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      debugPrint(
        '[Profile] Ignoring temporary file cleanup failure during $context: $error',
      );
    }
  }

  String _resolveEditableDisplayName(SelfProfile profile) {
    final candidate = profile.displayName.trim();
    if (candidate.isEmpty) {
      return '';
    }

    final phoneComparable = _normalizePhoneComparable(profile.phone);
    if (phoneComparable.isNotEmpty &&
        _normalizePhoneComparable(candidate) == phoneComparable) {
      return '';
    }

    return candidate;
  }

  String _normalizePhoneComparable(String raw) =>
      raw.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  void onDispose() {
    _userSubscription?.cancel();
    _selfProfileSubscription?.cancel();
    _maxRadiusSubscription?.cancel();
    _proximityPreferenceSubscription?.cancel();
    nameController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    editFieldController.dispose();
    radiusKmController.dispose();
    fixedOriginLatitudeController.dispose();
    fixedOriginLongitudeController.dispose();
    fixedOriginLabelController.dispose();
    localAvatarPathStreamValue.dispose();
    formVersionStreamValue.dispose();
    isProfileLoadingStreamValue.dispose();
    isMatchedPeopleLoadingStreamValue.dispose();
    matchedPeopleStreamValue.dispose();
    matchedPeopleErrorStreamValue.dispose();
    pendingInvitesCountStreamValue.dispose();
    confirmedEventsCountStreamValue.dispose();
    maxRadiusMetersStreamValue.dispose();
    isUsingFixedOriginStreamValue.dispose();
    activeOriginSummaryStreamValue.dispose();
    originPreferenceFeedbackStreamValue.dispose();
  }
}
