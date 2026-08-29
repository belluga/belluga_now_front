import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/inviteables_repository_contract.dart';
import 'package:belluga_now/domain/repositories/proximity_preferences_repository_contract.dart';
import 'package:belluga_now/domain/repositories/self_profile_repository_contract.dart';
import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/self_profile.dart';
import 'package:belluga_now/domain/user/user_profile_media_upload.dart';
import 'package:belluga_now/domain/user/value_objects/user_profile_media_bytes_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/presentation/tenant_public/profile/screens/profile_screen/controllers/profile_account_deletion_ui_phase.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ProfileScreenController implements Disposable {
  ProfileScreenController({
    AuthRepositoryContract? authRepository,
    AppDataRepositoryContract? appDataRepository,
    ProximityPreferencesRepositoryContract? proximityPreferencesRepository,
    SelfProfileRepositoryContract? selfProfileRepository,
    InviteablesRepositoryContract? inviteablesRepository,
  }) : _authRepository =
           authRepository ?? GetIt.I.get<AuthRepositoryContract>(),
       _appDataRepository =
           appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
       _proximityPreferencesRepository =
           proximityPreferencesRepository ??
           (GetIt.I.isRegistered<ProximityPreferencesRepositoryContract>()
               ? GetIt.I.get<ProximityPreferencesRepositoryContract>()
               : null),
       _selfProfileRepository =
           selfProfileRepository ??
           GetIt.I.get<SelfProfileRepositoryContract>(),
       _inviteablesRepository =
           inviteablesRepository ??
           GetIt.I.get<InviteablesRepositoryContract>() {
    _bindUserStream();
    _bindSelfProfileStream();
    _bindMaxRadiusStream();
    _bindProximityPreferenceStream();
  }

  final AuthRepositoryContract _authRepository;
  final AppDataRepositoryContract _appDataRepository;
  final ProximityPreferencesRepositoryContract? _proximityPreferencesRepository;
  final SelfProfileRepositoryContract _selfProfileRepository;
  final InviteablesRepositoryContract _inviteablesRepository;
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
  final StreamValue<Uint8List?> pendingAvatarBytesStreamValue =
      StreamValue<Uint8List?>();
  final StreamValue<int> formVersionStreamValue = StreamValue<int>(
    defaultValue: 0,
  );
  final StreamValue<bool> isProfileLoadingStreamValue = StreamValue<bool>(
    defaultValue: true,
  );
  final StreamValue<bool> isMatchedPeopleLoadingStreamValue = StreamValue<bool>(
    defaultValue: true,
  );
  final StreamValue<List<InviteableRecipient>> matchedPeopleStreamValue =
      StreamValue<List<InviteableRecipient>>(defaultValue: const []);
  final StreamValue<String> matchedPeopleErrorStreamValue = StreamValue<String>(
    defaultValue: '',
  );
  final StreamValue<int> pendingInvitesCountStreamValue = StreamValue<int>(
    defaultValue: 0,
  );
  final StreamValue<int> confirmedEventsCountStreamValue = StreamValue<int>(
    defaultValue: 0,
  );
  final StreamValue<int> invitesSentCountStreamValue = StreamValue<int>(
    defaultValue: 0,
  );
  final StreamValue<int> invitesAcceptedCountStreamValue = StreamValue<int>(
    defaultValue: 0,
  );
  final StreamValue<double> maxRadiusMetersStreamValue = StreamValue<double>(
    defaultValue: 50000,
  );
  final StreamValue<bool> isUsingFixedOriginStreamValue = StreamValue<bool>(
    defaultValue: false,
  );
  final StreamValue<String> activeOriginSummaryStreamValue =
      StreamValue<String>(defaultValue: 'Localização atual');
  final StreamValue<String?> originPreferenceFeedbackStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<ProfileAccountDeletionUiPhase>
  accountDeletionUiPhaseStreamValue =
      StreamValue<ProfileAccountDeletionUiPhase>(
        defaultValue: ProfileAccountDeletionUiPhase.idle,
      );
  final StreamValue<int> accountDeletionResolutionNavigationRequestStreamValue =
      StreamValue<int>(defaultValue: 0);

  String? _syncedUserId;
  String _initialName = '';
  String _initialDescription = '';
  SelfProfile? _currentProfile;
  UserProfileMediaUpload? _pendingAvatarUpload;
  Future<void>? _profileRefreshAction;
  Future<void>? _profileSaveAction;
  Future<void>? _avatarPickAction;
  bool _didInit = false;
  bool _isDisposed = false;
  Future<void>? _accountDeletionAction;

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
  bool get isProfileSaving => _profileSaveAction != null;
  bool get isProfileMutationBlocked =>
      _profileRefreshAction != null ||
      _profileSaveAction != null ||
      _avatarPickAction != null;

  bool syncFromUser(UserContract? user) {
    if (user == null) return false;
    final id = user.uuidValue.value.toString();
    if (id == _syncedUserId) return false;
    _syncedUserId = id;
    return true;
  }

  Future<void> init() async {
    _didInit = true;
    final hasCachedProfile =
        currentProfileStreamValue.value != null || _currentProfile != null;
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
          final hasCachedProfile =
              currentProfileStreamValue.value != null ||
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
    _selfProfileSubscription = currentProfileStreamValue.stream.listen((
      profile,
    ) {
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
    maxRadiusMetersStreamValue.addValue(
      _appDataRepository.maxRadiusMeters.value,
    );
    _maxRadiusSubscription = _appDataRepository
        .maxRadiusMetersStreamValue
        .stream
        .listen((value) {
          maxRadiusMetersStreamValue.addValue(value.value);
        });
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
    _proximityPreferenceSubscription = repository
        .proximityPreferenceStreamValue
        .stream
        .listen(_applyProximityPreference);
    _applyProximityPreference(repository.proximityPreference);
  }

  void _applyProximityPreference(ProximityPreference? preference) {
    final effectivePreference =
        preference ??
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
      fixedOriginLatitudeController.text = fixedReference.coordinate.latitude
          .toStringAsFixed(6);
      fixedOriginLongitudeController.text = fixedReference.coordinate.longitude
          .toStringAsFixed(6);
      fixedOriginLabelController.text = fixedReference.label ?? '';
    } else {
      fixedOriginLatitudeController.clear();
      fixedOriginLongitudeController.clear();
      fixedOriginLabelController.clear();
    }
  }

  String? saveOriginPreference({required bool useFixedOrigin}) {
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
          await repository.setFixedReference(fixedReference: fixedReference);
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

    final longitude = double.tryParse(
      fixedOriginLongitudeController.text.trim(),
    );
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

  Future<void> _persistOriginPreference(Future<void> Function() persist) async {
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

  Future<void> refreshProfile({bool silent = false}) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    final inFlight = _profileRefreshAction;
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<void> action;
    action = _refreshProfileOnce(silent: silent).whenComplete(() {
      if (identical(_profileRefreshAction, action)) {
        _profileRefreshAction = null;
        if (!_isDisposed) {
          bumpFormVersion();
        }
      }
    });
    _profileRefreshAction = action;
    bumpFormVersion();
    return action;
  }

  Future<void> _refreshProfileOnce({required bool silent}) async {
    if (!silent) {
      isProfileLoadingStreamValue.addValue(true);
    }
    try {
      await _selfProfileRepository.refreshCurrentProfile();
    } finally {
      if (!_isDisposed) {
        isProfileLoadingStreamValue.addValue(false);
      }
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
      await _inviteablesRepository.refreshInviteableRecipients();
      final recipients =
          _inviteablesRepository.inviteableRecipientsStreamValue.value ??
          const <InviteableRecipient>[];
      final filtered = recipients
          .where((recipient) {
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
          })
          .toList(growable: false);
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
    _syncedUserId = profile.userId.trim().isEmpty
        ? _syncedUserId
        : profile.userId;
    final resolvedDisplayName = _resolveEditableDisplayName(profile);
    _initialName = resolvedDisplayName;
    _initialDescription = profile.bio;
    nameController.text = resolvedDisplayName;
    descriptionController.text = profile.bio;
    phoneController.text = profile.phone;
    pendingInvitesCountStreamValue.addValue(profile.pendingInvitesCount);
    confirmedEventsCountStreamValue.addValue(profile.confirmedEventsCount);
    invitesSentCountStreamValue.addValue(profile.invitesSentCount);
    invitesAcceptedCountStreamValue.addValue(profile.invitesAcceptedCount);
    bumpFormVersion();
  }

  Future<void> pickAvatar(ImageSource source) {
    if (_isDisposed) {
      return Future<void>.value();
    }
    final inFlight = _avatarPickAction ?? _profileSaveAction;
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<void> action;
    action = _pickAvatarOnce(source).whenComplete(() {
      if (identical(_avatarPickAction, action)) {
        _avatarPickAction = null;
        if (!_isDisposed) {
          bumpFormVersion();
        }
      }
    });
    _avatarPickAction = action;
    bumpFormVersion();
    return action;
  }

  Future<void> _pickAvatarOnce(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (_isDisposed) return;
    _pendingAvatarUpload = UserProfileMediaUpload(
      bytesValue: UserProfileMediaBytesValue()..set(bytes),
      fileNameValue: GenericStringValue(defaultValue: '', isRequired: true)
        ..parse(_fileNameFromPath(picked.path)),
      mimeTypeValue: GenericStringValue(defaultValue: '', isRequired: false)
        ..parse(_inferImageMimeType(picked.path) ?? ''),
    );
    pendingAvatarBytesStreamValue.addValue(bytes);
    bumpFormVersion();
    await saveProfile();
  }

  Future<void> saveProfile() {
    if (_isDisposed) {
      return Future<void>.value();
    }
    final inFlight = _profileSaveAction;
    if (inFlight != null) {
      return inFlight;
    }

    final draftName = nameController.text.trim();
    final draftDescription = descriptionController.text.trim();
    final draftAvatarUpload = _pendingAvatarUpload;

    late final Future<void> action;
    action =
        _saveProfileAfterRefresh(
          draftName: draftName,
          draftDescription: draftDescription,
          draftAvatarUpload: draftAvatarUpload,
        ).whenComplete(() {
          if (identical(_profileSaveAction, action)) {
            _profileSaveAction = null;
            if (!_isDisposed) {
              bumpFormVersion();
            }
          }
        });
    _profileSaveAction = action;
    bumpFormVersion();
    return action;
  }

  Future<void> _saveProfileAfterRefresh({
    required String draftName,
    required String draftDescription,
    required UserProfileMediaUpload? draftAvatarUpload,
  }) async {
    final refresh = _profileRefreshAction;
    if (refresh != null) {
      await refresh;
    }
    if (_isDisposed) return;

    final hasNameChange = draftName != _initialName.trim();
    final hasDescriptionChange = draftDescription != _initialDescription.trim();
    final hasAvatarChange = draftAvatarUpload != null;

    if (!hasNameChange && !hasDescriptionChange && !hasAvatarChange) {
      return;
    }
    try {
      final updated = await _selfProfileRepository.updateCurrentProfile(
        displayNameValue: hasNameChange
            ? (UserDisplayNameValue(isRequired: false, minLenght: null)
                ..parse(draftName))
            : null,
        bioValue: hasDescriptionChange
            ? (DescriptionValue(defaultValue: '', minLenght: null)
                ..parse(draftDescription))
            : null,
        avatarUpload: draftAvatarUpload,
      );
      if (_isDisposed) return;
      if (identical(_pendingAvatarUpload, draftAvatarUpload)) {
        _pendingAvatarUpload = null;
        pendingAvatarBytesStreamValue.addValue(null);
      }
      _applySelfProfile(updated);
      if (updated.userId.trim().isNotEmpty) {
        _syncedUserId = updated.userId;
      }
    } catch (error, stackTrace) {
      debugPrint('ProfileScreenController.saveProfile failed');
      debugPrintStack(stackTrace: stackTrace);
      throw StateError(
        'Nao foi possivel salvar o perfil agora. Tente novamente.',
      );
    }
  }

  Future<void> logout() => _authRepository.logout();

  Future<void> deleteCurrentAccount() {
    final inFlight = _accountDeletionAction;
    if (inFlight != null) {
      return inFlight;
    }

    accountDeletionUiPhaseStreamValue.addValue(
      ProfileAccountDeletionUiPhase.deleting,
    );
    final action = _deleteCurrentAccountOnce().whenComplete(() {
      _accountDeletionAction = null;
    });
    _accountDeletionAction = action;
    return action;
  }

  Future<void> _deleteCurrentAccountOnce() async {
    final outcome = await _authRepository.deleteCurrentAccount();
    switch (outcome) {
      case AccountDeletionDispatchOutcome.preEraseRejected:
        accountDeletionUiPhaseStreamValue.addValue(
          ProfileAccountDeletionUiPhase.preEraseRejected,
        );
        return;
      case AccountDeletionDispatchOutcome.confirmed:
      case AccountDeletionDispatchOutcome.unknown:
        accountDeletionUiPhaseStreamValue.addValue(
          ProfileAccountDeletionUiPhase.idle,
        );
        accountDeletionResolutionNavigationRequestStreamValue.addValue(
          accountDeletionResolutionNavigationRequestStreamValue.value + 1,
        );
        return;
    }
  }

  DistanceInMetersValue _distanceInMetersValue(double raw) {
    final value = DistanceInMetersValue();
    value.parse(raw.toString());
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
    _isDisposed = true;
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
    pendingAvatarBytesStreamValue.dispose();
    formVersionStreamValue.dispose();
    isProfileLoadingStreamValue.dispose();
    isMatchedPeopleLoadingStreamValue.dispose();
    matchedPeopleStreamValue.dispose();
    matchedPeopleErrorStreamValue.dispose();
    pendingInvitesCountStreamValue.dispose();
    confirmedEventsCountStreamValue.dispose();
    invitesSentCountStreamValue.dispose();
    invitesAcceptedCountStreamValue.dispose();
    maxRadiusMetersStreamValue.dispose();
    isUsingFixedOriginStreamValue.dispose();
    activeOriginSummaryStreamValue.dispose();
    originPreferenceFeedbackStreamValue.dispose();
    accountDeletionUiPhaseStreamValue.dispose();
    accountDeletionResolutionNavigationRequestStreamValue.dispose();
  }
}
