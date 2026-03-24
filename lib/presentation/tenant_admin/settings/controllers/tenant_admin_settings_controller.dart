export 'tenant_admin_branding_asset_slot.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_branding_asset_slot.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminSettingsController implements Disposable {
  TenantAdminSettingsController({
    AppDataRepositoryContract? appDataRepository,
    TenantAdminSettingsRepositoryContract? settingsRepository,
    TenantAdminAccountProfilesRepositoryContract? accountProfilesRepository,
    TenantAdminStaticAssetsRepositoryContract? staticAssetsRepository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminTenantScopeContract? tenantScope,
    TenantAdminLocationSelectionContract? locationSelectionService,
    TenantAdminImageIngestionService? imageIngestionService,
  })  : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _settingsRepository = settingsRepository ??
            GetIt.I.get<TenantAdminSettingsRepositoryContract>(),
        _accountProfilesRepository = accountProfilesRepository ??
            (GetIt.I.isRegistered<
                    TenantAdminAccountProfilesRepositoryContract>()
                ? GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
                : null),
        _staticAssetsRepository = staticAssetsRepository ??
            (GetIt.I.isRegistered<TenantAdminStaticAssetsRepositoryContract>()
                ? GetIt.I.get<TenantAdminStaticAssetsRepositoryContract>()
                : null),
        _taxonomiesRepository = taxonomiesRepository ??
            (GetIt.I.isRegistered<TenantAdminTaxonomiesRepositoryContract>()
                ? GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>()
                : null),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null),
        _locationSelectionService = locationSelectionService ??
            GetIt.I.get<TenantAdminLocationSelectionContract>(),
        _imageIngestionService = imageIngestionService ??
            (GetIt.I.isRegistered<TenantAdminImageIngestionService>()
                ? GetIt.I.get<TenantAdminImageIngestionService>()
                : TenantAdminImageIngestionService());

  final AppDataRepositoryContract _appDataRepository;
  final TenantAdminSettingsRepositoryContract _settingsRepository;
  final TenantAdminAccountProfilesRepositoryContract?
      _accountProfilesRepository;
  final TenantAdminStaticAssetsRepositoryContract? _staticAssetsRepository;
  final TenantAdminTaxonomiesRepositoryContract? _taxonomiesRepository;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminLocationSelectionContract _locationSelectionService;
  final TenantAdminImageIngestionService _imageIngestionService;

  static const List<String> telemetryTypes = [
    'mixpanel',
    'firebase',
    'webhook',
  ];

  final StreamValue<bool> isRemoteLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> remoteErrorStreamValue = StreamValue<String?>();
  final StreamValue<String?> remoteSuccessStreamValue = StreamValue<String?>();
  final StreamValue<bool> mapUiSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<TenantAdminMapUiSettings> mapUiSettingsStreamValue =
      StreamValue<TenantAdminMapUiSettings>(
    defaultValue: TenantAdminMapUiSettings.empty(),
  );
  final StreamValue<bool> appLinksSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<TenantAdminAppLinksSettings> appLinksSettingsStreamValue =
      StreamValue<TenantAdminAppLinksSettings>(
    defaultValue: TenantAdminAppLinksSettings.empty(),
  );
  final StreamValue<List<String>> appLinksIosPathsSelectionStreamValue =
      StreamValue<List<String>>(
    defaultValue: List<String>.from(
      TenantAdminAppLinksSettings.canonicalIosPaths,
      growable: false,
    ),
  );
  final StreamValue<TenantAdminMapFilterRuleCatalog>
      mapFilterRuleCatalogStreamValue =
      StreamValue<TenantAdminMapFilterRuleCatalog>(
    defaultValue: const TenantAdminMapFilterRuleCatalog.empty(),
  );
  final StreamValue<bool> mapFilterRuleCatalogLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);

  final StreamValue<bool> firebaseSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> pushSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> telemetrySubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> brandingSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<TenantAdminBrandingBrightness>
      brandingBrightnessStreamValue =
      StreamValue<TenantAdminBrandingBrightness>(
    defaultValue: TenantAdminBrandingBrightness.light,
  );
  final StreamValue<XFile?> brandingLightLogoFileStreamValue =
      StreamValue<XFile?>();
  final StreamValue<XFile?> brandingDarkLogoFileStreamValue =
      StreamValue<XFile?>();
  final StreamValue<XFile?> brandingLightIconFileStreamValue =
      StreamValue<XFile?>();
  final StreamValue<XFile?> brandingDarkIconFileStreamValue =
      StreamValue<XFile?>();
  final StreamValue<XFile?> brandingPwaIconFileStreamValue =
      StreamValue<XFile?>();

  final StreamValue<String?> brandingLightLogoUrlStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> brandingDarkLogoUrlStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> brandingLightIconUrlStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> brandingDarkIconUrlStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> brandingPwaIconUrlStreamValue =
      StreamValue<String?>();

  final StreamValue<TenantAdminTelemetrySettingsSnapshot>
      telemetrySnapshotStreamValue =
      StreamValue<TenantAdminTelemetrySettingsSnapshot>(
    defaultValue: TenantAdminTelemetrySettingsSnapshot.empty(),
  );
  final StreamValue<String> selectedTelemetryTypeStreamValue =
      StreamValue<String>(defaultValue: telemetryTypes.first);
  final StreamValue<bool> telemetryTrackAllStreamValue =
      StreamValue<bool>(defaultValue: false);

  final TextEditingController firebaseApiKeyController =
      TextEditingController();
  final TextEditingController firebaseAppIdController = TextEditingController();
  final TextEditingController firebaseProjectIdController =
      TextEditingController();
  final TextEditingController firebaseMessagingSenderIdController =
      TextEditingController();
  final TextEditingController firebaseStorageBucketController =
      TextEditingController();

  final TextEditingController pushMaxTtlDaysController =
      TextEditingController();
  final TextEditingController pushMaxPerMinuteController =
      TextEditingController();
  final TextEditingController pushMaxPerHourController =
      TextEditingController();

  final TextEditingController telemetryEventsController =
      TextEditingController();
  final TextEditingController telemetryTokenController =
      TextEditingController();
  final TextEditingController telemetryUrlController = TextEditingController();
  final TextEditingController brandingTenantNameController =
      TextEditingController();
  final TextEditingController brandingPrimarySeedColorController =
      TextEditingController();
  final TextEditingController brandingSecondarySeedColorController =
      TextEditingController();
  final TextEditingController mapDefaultOriginLatitudeController =
      TextEditingController();
  final TextEditingController mapDefaultOriginLongitudeController =
      TextEditingController();
  final TextEditingController mapDefaultOriginLabelController =
      TextEditingController();
  final TextEditingController appLinksAndroidPackageNameController =
      TextEditingController();
  final TextEditingController appLinksAndroidFingerprintsController =
      TextEditingController();
  final TextEditingController appLinksIosTeamIdController =
      TextEditingController();
  final TextEditingController appLinksIosBundleIdController =
      TextEditingController();
  static const int _mapFilterKeyMaxLength = 64;

  bool _initialized = false;
  String? _initializedTenantDomain;
  StreamSubscription<String?>? _tenantScopeSubscription;
  StreamSubscription<TenantAdminBrandingSettings?>? _brandingSubscription;
  StreamSubscription<TenantAdminLocation?>? _locationSelectionSubscription;
  TenantAdminMapUiSettings _mapUiSettings = TenantAdminMapUiSettings.empty();
  bool _localPreferencesFlowBound = false;

  AppData get appData => _appDataRepository.appData;
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      _appDataRepository.themeModeStreamValue;
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _appDataRepository.maxRadiusMetersStreamValue;
  StreamValue<TenantAdminBrandingSettings?> get brandingSettingsStreamValue =>
      _settingsRepository.brandingSettingsStreamValue;
  List<String> get appLinksCanonicalIosPaths =>
      TenantAdminAppLinksSettings.canonicalIosPaths;

  void updateAppLinksIosPathsSelection(List<String> selectedPaths) {
    final sanitized = selectedPaths
        .map((entry) => entry.trim())
        .where((entry) => appLinksCanonicalIosPaths.contains(entry))
        .toSet()
        .toList(growable: false);
    appLinksIosPathsSelectionStreamValue.addValue(
      sanitized.isEmpty
          ? List<String>.from(appLinksCanonicalIosPaths, growable: false)
          : sanitized,
    );
  }

  Future<void> init({
    bool loadBranding = true,
  }) async {
    _bindTenantScope();
    _bindBrandingRepositoryStream();
    final normalizedTenantDomain =
        _normalizeTenantDomain(_tenantScope?.selectedTenantDomain);
    if (_initialized) {
      if (_initializedTenantDomain != normalizedTenantDomain) {
        _initializedTenantDomain = normalizedTenantDomain;
        _resetTenantScopedForms();
        if (loadBranding &&
            (normalizedTenantDomain != null || _tenantScope == null)) {
          await loadBrandingSettings();
        }
      }
      return;
    }
    _initialized = true;
    _initializedTenantDomain = normalizedTenantDomain;
    _seedFirebaseAndPushFromSnapshot();
    _clearBrandingDraftForRemoteLoad();
    if (loadBranding &&
        (normalizedTenantDomain != null || _tenantScope == null)) {
      await loadBrandingSettings();
    }
  }

  void _bindTenantScope() {
    if (_tenantScopeSubscription != null || _tenantScope == null) {
      return;
    }
    final tenantScope = _tenantScope;
    _tenantScopeSubscription =
        tenantScope.selectedTenantDomainStreamValue.stream.listen(
      (tenantDomain) {
        final normalized = _normalizeTenantDomain(tenantDomain);
        if (normalized == _initializedTenantDomain) {
          return;
        }
        _initializedTenantDomain = normalized;
        _resetTenantScopedForms();
        if (normalized != null) {
          unawaited(loadBrandingSettings());
          if (_localPreferencesFlowBound) {
            unawaited(loadMapUiSettings());
          }
        }
      },
    );
  }

  void _bindLocationSelection() {
    if (_locationSelectionSubscription != null) {
      return;
    }
    _locationSelectionSubscription = _locationSelectionService
        .confirmedLocationStreamValue.stream
        .listen((location) {
      if (location == null) {
        return;
      }
      mapDefaultOriginLatitudeController.text =
          location.latitude.toStringAsFixed(6);
      mapDefaultOriginLongitudeController.text =
          location.longitude.toStringAsFixed(6);
      _locationSelectionService.clearConfirmedLocation();
    });
  }

  void bindLocalPreferencesFlow() {
    _localPreferencesFlowBound = true;
    _bindLocationSelection();
  }

  void _bindBrandingRepositoryStream() {
    if (_brandingSubscription != null) {
      return;
    }
    _brandingSubscription = _settingsRepository
        .brandingSettingsStreamValue.stream
        .listen((settings) {
      if (settings == null) {
        return;
      }
      _applyBrandingSettings(settings);
    });
  }

  Future<void> updateThemeMode(ThemeMode mode) {
    return _appDataRepository.setThemeMode(mode);
  }

  Future<void> updateMaxRadiusMeters(double meters) {
    return _appDataRepository.setMaxRadiusMeters(meters);
  }

  Future<void> loadTechnicalIntegrationsSettings() async {
    isRemoteLoadingStreamValue.addValue(true);
    remoteErrorStreamValue.addValue(null);

    final errors = <String>[];
    try {
      try {
        final firebaseSettings =
            await _settingsRepository.fetchFirebaseSettings();
        if (firebaseSettings != null) {
          _applyFirebaseSettings(firebaseSettings);
        }
      } catch (error) {
        errors.add(error.toString());
      }

      try {
        final telemetrySnapshot =
            await _settingsRepository.fetchTelemetrySettings();
        telemetrySnapshotStreamValue.addValue(telemetrySnapshot);
      } catch (error) {
        errors.add(error.toString());
      }

      try {
        final appLinksSettings =
            await _settingsRepository.fetchAppLinksSettings();
        _applyAppLinksSettings(appLinksSettings);
      } catch (error) {
        errors.add(error.toString());
      }

      if (errors.isEmpty) {
        remoteErrorStreamValue.addValue(null);
      } else {
        remoteErrorStreamValue.addValue(errors.first);
      }
    } finally {
      isRemoteLoadingStreamValue.addValue(false);
    }
  }

  Future<void> loadBrandingSettings() async {
    isRemoteLoadingStreamValue.addValue(true);
    remoteErrorStreamValue.addValue(null);
    try {
      await _settingsRepository.fetchBrandingSettings();
      remoteErrorStreamValue.addValue(null);
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      isRemoteLoadingStreamValue.addValue(false);
    }
  }

  Future<void> loadMapUiSettings() async {
    isRemoteLoadingStreamValue.addValue(true);
    remoteErrorStreamValue.addValue(null);
    try {
      final settings = await _settingsRepository.fetchMapUiSettings();
      _applyMapUiSettings(settings);
      await loadMapFilterRuleCatalog();
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      isRemoteLoadingStreamValue.addValue(false);
    }
  }

  Future<void> loadMapFilterRuleCatalog({bool force = false}) async {
    if (mapFilterRuleCatalogLoadingStreamValue.value) {
      return;
    }
    if (!force && !mapFilterRuleCatalogStreamValue.value.isEmpty) {
      return;
    }

    mapFilterRuleCatalogLoadingStreamValue.addValue(true);
    try {
      final accountRepo = _accountProfilesRepository;
      final staticRepo = _staticAssetsRepository;
      final taxonomyRepo = _taxonomiesRepository;
      if (accountRepo == null || staticRepo == null || taxonomyRepo == null) {
        mapFilterRuleCatalogStreamValue
            .addValue(const TenantAdminMapFilterRuleCatalog.empty());
        return;
      }

      await Future.wait<void>([
        accountRepo.loadAllProfileTypes(),
        staticRepo.loadAllStaticProfileTypes(),
        taxonomyRepo.loadAllTaxonomies(),
      ]);

      final accountTypes = accountRepo.profileTypesStreamValue.value ??
          const <TenantAdminProfileTypeDefinition>[];
      final staticTypes = staticRepo.staticProfileTypesStreamValue.value ??
          const <TenantAdminStaticProfileTypeDefinition>[];
      final taxonomies = taxonomyRepo.taxonomiesStreamValue.value ??
          const <TenantAdminTaxonomyDefinition>[];

      final termsByTaxonomySlug =
          await _loadTermsByTaxonomySlug(taxonomies: taxonomies);
      final catalog = _buildMapFilterRuleCatalog(
        accountTypes: accountTypes,
        staticTypes: staticTypes,
        taxonomies: taxonomies,
        termsByTaxonomySlug: termsByTaxonomySlug,
      );
      mapFilterRuleCatalogStreamValue.addValue(catalog);
    } catch (error) {
      remoteErrorStreamValue.addValue(
        'Não foi possível carregar catálogo de regras dos filtros: $error',
      );
    } finally {
      mapFilterRuleCatalogLoadingStreamValue.addValue(false);
    }
  }

  TenantAdminLocation? currentMapDefaultOriginLocation() {
    final lat =
        tenantAdminParseLatitude(mapDefaultOriginLatitudeController.text);
    final lng =
        tenantAdminParseLongitude(mapDefaultOriginLongitudeController.text);
    if (lat == null || lng == null) {
      return null;
    }
    return TenantAdminLocation(latitude: lat, longitude: lng);
  }

  Future<void> saveMapUiSettings() async {
    final latitudeRaw = mapDefaultOriginLatitudeController.text.trim();
    if (latitudeRaw.isEmpty) {
      remoteErrorStreamValue.addValue(
        'Latitude da origem padrão é obrigatória.',
      );
      return;
    }
    final latitude = tenantAdminParseLatitude(latitudeRaw);
    if (latitude == null) {
      remoteErrorStreamValue.addValue(
        'Latitude da origem padrão inválida.',
      );
      return;
    }

    final longitudeRaw = mapDefaultOriginLongitudeController.text.trim();
    if (longitudeRaw.isEmpty) {
      remoteErrorStreamValue.addValue(
        'Longitude da origem padrão é obrigatória.',
      );
      return;
    }
    final longitude = tenantAdminParseLongitude(longitudeRaw);
    if (longitude == null) {
      remoteErrorStreamValue.addValue(
        'Longitude da origem padrão inválida.',
      );
      return;
    }

    mapUiSubmittingStreamValue.addValue(true);
    try {
      final label = mapDefaultOriginLabelController.text.trim();
      final nextSettings = _mapUiSettings.applyDefaultOrigin(
        TenantAdminMapDefaultOrigin(
          lat: latitude,
          lng: longitude,
          label: label.isEmpty ? null : label,
        ),
      );
      final updated = await _settingsRepository.updateMapUiSettings(
        settings: nextSettings,
      );
      _applyMapUiSettings(updated);
      await _refreshAppDataSnapshot();
      _reportSuccess('Origem padrão atualizada com sucesso.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      mapUiSubmittingStreamValue.addValue(false);
    }
  }

  Future<void> saveMapFilters() async {
    mapUiSubmittingStreamValue.addValue(true);
    try {
      final updated = await _settingsRepository.updateMapUiSettings(
        settings: _mapUiSettings,
      );
      _applyMapUiSettings(updated);
      await _refreshAppDataSnapshot();
      _reportSuccess('Filtros do mapa atualizados com sucesso.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      mapUiSubmittingStreamValue.addValue(false);
    }
  }

  void addMapFilterItem() {
    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    final nextIndex = current.length + 1;
    final defaultKey = _buildMapFilterDefaultKey(nextIndex, current);
    current.add(
      TenantAdminMapFilterCatalogItem(
        key: defaultKey,
        label: 'Filtro ${nextIndex.toString()}',
      ),
    );
    _replaceMapFilters(current);
  }

  void removeMapFilterItem(int index) {
    if (index < 0 || index >= _mapUiSettings.filters.length) {
      return;
    }
    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    )..removeAt(index);
    _replaceMapFilters(current);
  }

  void moveMapFilterItemUp(int index) {
    if (index <= 0 || index >= _mapUiSettings.filters.length) {
      return;
    }
    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    final item = current.removeAt(index);
    current.insert(index - 1, item);
    _replaceMapFilters(current);
  }

  void moveMapFilterItemDown(int index) {
    if (index < 0 || index >= _mapUiSettings.filters.length - 1) {
      return;
    }
    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    final item = current.removeAt(index);
    current.insert(index + 1, item);
    _replaceMapFilters(current);
  }

  void updateMapFilterItemKey(int index, String rawKey) {
    final item = _mapFilterAt(index);
    if (item == null) {
      return;
    }
    final normalized = _normalizeMapFilterKey(rawKey);
    if (normalized.isEmpty) {
      remoteErrorStreamValue.addValue(
        'A chave do filtro deve conter letras, números, hífen ou underscore.',
      );
      return;
    }
    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    current[index] = item.copyWith(key: normalized);
    _replaceMapFilters(current);
    remoteErrorStreamValue.addValue(null);
  }

  void updateMapFilterItemLabel(int index, String rawLabel) {
    final item = _mapFilterAt(index);
    if (item == null) {
      return;
    }
    final label = rawLabel.trim();
    if (label.isEmpty) {
      remoteErrorStreamValue.addValue('O rótulo do filtro é obrigatório.');
      return;
    }
    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    current[index] = item.copyWith(label: label);
    _replaceMapFilters(current);
    remoteErrorStreamValue.addValue(null);
  }

  void updateMapFilterItemRule(
    int index,
    TenantAdminMapFilterQuery query,
  ) {
    final item = _mapFilterAt(index);
    if (item == null) {
      return;
    }
    final source = query.source;
    if (source == null) {
      remoteErrorStreamValue.addValue(
        'Selecione a origem do filtro (Conta, Asset ou Evento).',
      );
      return;
    }
    final sanitized = TenantAdminMapFilterQuery(
      source: source,
      types: query.types
          .map((entry) => entry.trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toSet()
          .toList(growable: false),
      taxonomy: query.taxonomy
          .map((entry) => entry.trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toSet()
          .toList(growable: false),
    );
    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    current[index] = item.copyWith(query: sanitized);
    _replaceMapFilters(current);
    remoteErrorStreamValue.addValue(null);
  }

  void clearMapFilterItemImage(int index) {
    final item = _mapFilterAt(index);
    if (item == null) {
      return;
    }
    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    current[index] = item.copyWith(clearImageUri: true);
    _replaceMapFilters(current);
  }

  Future<void> uploadMapFilterItemImage({
    required int index,
    required XFile file,
  }) async {
    final item = _mapFilterAt(index);
    if (item == null) {
      return;
    }
    final key = _normalizeMapFilterKey(item.key);
    if (key.isEmpty) {
      remoteErrorStreamValue.addValue(
        'Defina uma chave válida para o filtro antes de enviar a imagem.',
      );
      return;
    }

    final upload = await _imageIngestionService.buildUpload(
      file,
      slot: TenantAdminImageSlot.mapFilter,
    );
    if (upload == null) {
      remoteErrorStreamValue.addValue(
        'Não foi possível preparar a imagem do filtro.',
      );
      return;
    }

    try {
      final imageUri = await _settingsRepository.uploadMapFilterImage(
        key: key,
        upload: upload,
      );
      final current = List<TenantAdminMapFilterCatalogItem>.from(
        _mapUiSettings.filters,
      );
      current[index] = item.copyWith(
        key: key,
        imageUri: imageUri,
      );
      _replaceMapFilters(current);
      _reportSuccess('Imagem do filtro atualizada.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    }
  }

  Future<void> loadRemoteSettings() async {
    await loadBrandingSettings();
  }

  Future<void> saveFirebaseSettings() async {
    final parsed = _buildFirebaseSettings();
    if (parsed == null) {
      remoteErrorStreamValue.addValue(
        'Preencha todos os campos do Firebase antes de salvar.',
      );
      return;
    }

    firebaseSubmittingStreamValue.addValue(true);
    try {
      final updated = await _settingsRepository.updateFirebaseSettings(
        settings: parsed,
      );
      _applyFirebaseSettings(updated);
      _reportSuccess('Firebase atualizado com sucesso.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      firebaseSubmittingStreamValue.addValue(false);
    }
  }

  Future<void> savePushSettings() async {
    final parsed = _buildPushSettings();
    if (parsed == null) {
      remoteErrorStreamValue.addValue(
        'Push inválido. Informe TTL e throttles com números positivos.',
      );
      return;
    }

    pushSubmittingStreamValue.addValue(true);
    try {
      final updated = await _settingsRepository.updatePushSettings(
        settings: parsed,
      );
      _applyPushSettings(updated);
      _reportSuccess('Push atualizado com sucesso.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      pushSubmittingStreamValue.addValue(false);
    }
  }

  Future<void> saveAppLinksSettings() async {
    final parsed = _buildAppLinksSettings();
    if (parsed == null) {
      return;
    }

    appLinksSubmittingStreamValue.addValue(true);
    try {
      final updated = await _settingsRepository.updateAppLinksSettings(
        settings: parsed,
      );
      _applyAppLinksSettings(updated);
      _reportSuccess('App Links atualizados com sucesso.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      appLinksSubmittingStreamValue.addValue(false);
    }
  }

  void selectBrandingBrightness(TenantAdminBrandingBrightness brightness) {
    brandingBrightnessStreamValue.addValue(brightness);
  }

  StreamValue<XFile?> brandingFileStream(
    TenantAdminBrandingAssetSlot slot,
  ) {
    return switch (slot) {
      TenantAdminBrandingAssetSlot.lightLogo =>
        brandingLightLogoFileStreamValue,
      TenantAdminBrandingAssetSlot.darkLogo => brandingDarkLogoFileStreamValue,
      TenantAdminBrandingAssetSlot.lightIcon =>
        brandingLightIconFileStreamValue,
      TenantAdminBrandingAssetSlot.darkIcon => brandingDarkIconFileStreamValue,
      TenantAdminBrandingAssetSlot.pwaIcon => brandingPwaIconFileStreamValue,
    };
  }

  StreamValue<String?> brandingUrlStream(
    TenantAdminBrandingAssetSlot slot,
  ) {
    return switch (slot) {
      TenantAdminBrandingAssetSlot.lightLogo => brandingLightLogoUrlStreamValue,
      TenantAdminBrandingAssetSlot.darkLogo => brandingDarkLogoUrlStreamValue,
      TenantAdminBrandingAssetSlot.lightIcon => brandingLightIconUrlStreamValue,
      TenantAdminBrandingAssetSlot.darkIcon => brandingDarkIconUrlStreamValue,
      TenantAdminBrandingAssetSlot.pwaIcon => brandingPwaIconUrlStreamValue,
    };
  }

  void updateBrandingFile(
    TenantAdminBrandingAssetSlot slot,
    XFile? file,
  ) {
    brandingFileStream(slot).addValue(file);
    if (file != null) {
      brandingUrlStream(slot).addValue(null);
    }
  }

  void clearBrandingFile(TenantAdminBrandingAssetSlot slot) {
    brandingFileStream(slot).addValue(null);
  }

  Future<void> saveBranding({
    required TenantAdminMediaUpload? lightLogoUpload,
    required TenantAdminMediaUpload? darkLogoUpload,
    required TenantAdminMediaUpload? lightIconUpload,
    required TenantAdminMediaUpload? darkIconUpload,
    required TenantAdminMediaUpload? pwaIconUpload,
  }) async {
    final input = _buildBrandingUpdateInput(
      lightLogoUpload: lightLogoUpload,
      darkLogoUpload: darkLogoUpload,
      lightIconUpload: lightIconUpload,
      darkIconUpload: darkIconUpload,
      pwaIconUpload: pwaIconUpload,
    );
    if (input == null) {
      return;
    }

    brandingSubmittingStreamValue.addValue(true);
    try {
      await _settingsRepository.updateBranding(input: input);
      _reportSuccess('Branding atualizado com sucesso.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      brandingSubmittingStreamValue.addValue(false);
    }
  }

  void selectTelemetryType(String type) {
    if (!telemetryTypes.contains(type)) {
      return;
    }
    selectedTelemetryTypeStreamValue.addValue(type);
  }

  Future<XFile?> pickBrandingImageFromDevice({
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.pickFromDevice(slot: slot);
  }

  Future<XFile> fetchBrandingImageFromUrlForCrop({
    required String imageUrl,
  }) {
    return _imageIngestionService.fetchFromUrlForCrop(imageUrl: imageUrl);
  }

  Future<Uint8List> readImageBytesForCrop(XFile sourceFile) {
    return _imageIngestionService.readBytesForCrop(sourceFile);
  }

  Future<XFile> prepareCroppedImage(
    Uint8List croppedData, {
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.prepareBytesAsXFile(
      croppedData,
      slot: slot,
      applyAspectCrop: false,
    );
  }

  Future<TenantAdminMediaUpload?> buildBrandingUpload(
    XFile? file, {
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.buildUpload(file, slot: slot);
  }

  void updateTelemetryTrackAll(bool value) {
    telemetryTrackAllStreamValue.addValue(value);
  }

  void prefillTelemetryForm(TenantAdminTelemetryIntegration integration) {
    selectedTelemetryTypeStreamValue.addValue(integration.type);
    telemetryTrackAllStreamValue.addValue(integration.trackAll);
    telemetryEventsController.text = integration.events.join(', ');
    telemetryTokenController.text = integration.token ?? '';
    telemetryUrlController.text = integration.url ?? '';
  }

  void clearTelemetryForm() {
    selectedTelemetryTypeStreamValue.addValue(telemetryTypes.first);
    telemetryTrackAllStreamValue.addValue(false);
    telemetryEventsController.clear();
    telemetryTokenController.clear();
    telemetryUrlController.clear();
  }

  Future<void> saveTelemetryIntegration() async {
    final type = selectedTelemetryTypeStreamValue.value.trim();
    final trackAll = telemetryTrackAllStreamValue.value;
    final events = _parseCsv(telemetryEventsController.text);

    if (type.isEmpty) {
      remoteErrorStreamValue.addValue(
        'Tipo de integração de telemetry é obrigatório.',
      );
      return;
    }
    if (!trackAll && events.isEmpty) {
      remoteErrorStreamValue.addValue(
        'Informe ao menos um evento quando track_all estiver desativado.',
      );
      return;
    }

    telemetrySubmittingStreamValue.addValue(true);
    try {
      final snapshot = await _settingsRepository.upsertTelemetryIntegration(
        integration: TenantAdminTelemetryIntegration(
          type: type,
          trackAll: trackAll,
          events: events,
          token: telemetryTokenController.text.trim().isEmpty
              ? null
              : telemetryTokenController.text.trim(),
          url: telemetryUrlController.text.trim().isEmpty
              ? null
              : telemetryUrlController.text.trim(),
        ),
      );
      telemetrySnapshotStreamValue.addValue(snapshot);
      _reportSuccess('Integração de telemetry salva.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      telemetrySubmittingStreamValue.addValue(false);
    }
  }

  Future<void> deleteTelemetryIntegration(String type) async {
    if (type.trim().isEmpty) {
      return;
    }
    telemetrySubmittingStreamValue.addValue(true);
    try {
      final snapshot = await _settingsRepository.deleteTelemetryIntegration(
        type: type,
      );
      telemetrySnapshotStreamValue.addValue(snapshot);
      _reportSuccess('Integração de telemetry removida.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      telemetrySubmittingStreamValue.addValue(false);
    }
  }

  void clearStatusMessages() {
    remoteErrorStreamValue.addValue(null);
    remoteSuccessStreamValue.addValue(null);
  }

  void _seedFirebaseAndPushFromSnapshot() {
    final firebase = appData.firebaseSettings;
    if (firebase != null) {
      firebaseApiKeyController.text = firebase.apiKey;
      firebaseAppIdController.text = firebase.appId;
      firebaseProjectIdController.text = firebase.projectId;
      firebaseMessagingSenderIdController.text = firebase.messagingSenderId;
      firebaseStorageBucketController.text = firebase.storageBucket;
    }

    final push = appData.pushSettings;
    final maxPerMinute = _parseInt(push?.throttles['max_per_minute']) ?? 60;
    final maxPerHour = _parseInt(push?.throttles['max_per_hour']) ?? 600;
    pushMaxTtlDaysController.text = '30';
    pushMaxPerMinuteController.text = '$maxPerMinute';
    pushMaxPerHourController.text = '$maxPerHour';
  }

  void _resetTenantScopedForms() {
    _settingsRepository.clearBrandingSettings();
    clearStatusMessages();
    telemetrySnapshotStreamValue
        .addValue(TenantAdminTelemetrySettingsSnapshot.empty());
    clearTelemetryForm();
    clearBrandingFile(TenantAdminBrandingAssetSlot.lightLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.lightIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.pwaIcon);
    _seedFirebaseAndPushFromSnapshot();
    _clearBrandingDraftForRemoteLoad();
    _resetMapUiDraft();
    _resetAppLinksDraft();
  }

  void _clearBrandingDraftForRemoteLoad() {
    brandingTenantNameController.clear();
    brandingPrimarySeedColorController.clear();
    brandingSecondarySeedColorController.clear();
    brandingBrightnessStreamValue.addValue(TenantAdminBrandingBrightness.light);
    brandingLightLogoUrlStreamValue.addValue(null);
    brandingDarkLogoUrlStreamValue.addValue(null);
    brandingLightIconUrlStreamValue.addValue(null);
    brandingDarkIconUrlStreamValue.addValue(null);
    brandingPwaIconUrlStreamValue.addValue(null);
  }

  void _resetAppLinksDraft() {
    appLinksSettingsStreamValue.addValue(TenantAdminAppLinksSettings.empty());
    appLinksSubmittingStreamValue.addValue(false);
    appLinksIosPathsSelectionStreamValue.addValue(
      List<String>.from(
        TenantAdminAppLinksSettings.canonicalIosPaths,
        growable: false,
      ),
    );
    appLinksAndroidPackageNameController.clear();
    appLinksAndroidFingerprintsController.clear();
    appLinksIosTeamIdController.clear();
    appLinksIosBundleIdController.clear();
  }

  TenantAdminFirebaseSettings? _buildFirebaseSettings() {
    final apiKey = firebaseApiKeyController.text.trim();
    final appId = firebaseAppIdController.text.trim();
    final projectId = firebaseProjectIdController.text.trim();
    final senderId = firebaseMessagingSenderIdController.text.trim();
    final storageBucket = firebaseStorageBucketController.text.trim();
    if (apiKey.isEmpty ||
        appId.isEmpty ||
        projectId.isEmpty ||
        senderId.isEmpty ||
        storageBucket.isEmpty) {
      return null;
    }
    return TenantAdminFirebaseSettings(
      apiKey: apiKey,
      appId: appId,
      projectId: projectId,
      messagingSenderId: senderId,
      storageBucket: storageBucket,
    );
  }

  TenantAdminPushSettings? _buildPushSettings() {
    final ttlDays = _parsePositiveInt(pushMaxTtlDaysController.text);
    final maxPerMinute = _parsePositiveInt(pushMaxPerMinuteController.text);
    final maxPerHour = _parsePositiveInt(pushMaxPerHourController.text);
    if (ttlDays == null || maxPerMinute == null || maxPerHour == null) {
      return null;
    }
    return TenantAdminPushSettings(
      maxTtlDays: ttlDays,
      maxPerMinute: maxPerMinute,
      maxPerHour: maxPerHour,
    );
  }

  TenantAdminAppLinksSettings? _buildAppLinksSettings() {
    final androidPackageName =
        _normalizeOptionalText(appLinksAndroidPackageNameController.text);
    if (androidPackageName != null &&
        !_isValidAndroidPackageName(androidPackageName)) {
      remoteErrorStreamValue.addValue('Package name Android inválido.');
      return null;
    }

    final fingerprints = _parseDelimitedList(
      appLinksAndroidFingerprintsController.text,
    ).map((entry) => entry.toUpperCase()).toList(growable: false);
    if (fingerprints.isEmpty) {
      remoteErrorStreamValue.addValue(
        'Informe ao menos um fingerprint SHA-256.',
      );
      return null;
    }
    if (androidPackageName == null) {
      remoteErrorStreamValue.addValue(
        'Configure Android package antes de salvar fingerprints.',
      );
      return null;
    }
    final invalidFingerprint = fingerprints.firstWhere(
      (entry) => !_isValidSha256Fingerprint(entry),
      orElse: () => '',
    );
    if (invalidFingerprint.isNotEmpty) {
      remoteErrorStreamValue.addValue(
        'Fingerprint SHA-256 inválido: $invalidFingerprint',
      );
      return null;
    }

    final iosTeamId = _normalizeOptionalText(appLinksIosTeamIdController.text);
    final iosBundleId =
        _normalizeOptionalText(appLinksIosBundleIdController.text);
    if ((iosTeamId == null) != (iosBundleId == null)) {
      remoteErrorStreamValue.addValue(
        'Preencha team_id e bundle_id do iOS juntos, ou deixe ambos vazios.',
      );
      return null;
    }
    if (iosTeamId != null && !_isValidIosTeamId(iosTeamId)) {
      remoteErrorStreamValue.addValue('team_id do iOS inválido.');
      return null;
    }
    if (iosBundleId != null && !_isValidIosBundleId(iosBundleId)) {
      remoteErrorStreamValue.addValue('bundle_id do iOS inválido.');
      return null;
    }

    final iosPaths =
        List<String>.from(appLinksIosPathsSelectionStreamValue.value);
    if (iosTeamId != null && iosPaths.isEmpty) {
      remoteErrorStreamValue.addValue(
        'Informe ao menos um path iOS para Universal Links.',
      );
      return null;
    }

    try {
      return appLinksSettingsStreamValue.value.applyValues(
        androidAppIdentifier: androidPackageName,
        androidSha256CertFingerprints: fingerprints,
        iosTeamId: iosTeamId,
        iosBundleId: iosBundleId,
        iosPaths: iosPaths,
      );
    } catch (_) {
      remoteErrorStreamValue.addValue(
        'App Links inválido. Revise package, fingerprints, team_id e bundle_id.',
      );
      return null;
    }
  }

  TenantAdminBrandingUpdateInput? _buildBrandingUpdateInput({
    required TenantAdminMediaUpload? lightLogoUpload,
    required TenantAdminMediaUpload? darkLogoUpload,
    required TenantAdminMediaUpload? lightIconUpload,
    required TenantAdminMediaUpload? darkIconUpload,
    required TenantAdminMediaUpload? pwaIconUpload,
  }) {
    final tenantName = brandingTenantNameController.text.trim();
    if (tenantName.isEmpty) {
      remoteErrorStreamValue.addValue('Nome do tenant e obrigatorio.');
      return null;
    }

    final primary = _normalizeHexColor(brandingPrimarySeedColorController.text);
    if (primary == null) {
      remoteErrorStreamValue.addValue(
        'Cor primaria invalida. Use formato #RRGGBB.',
      );
      return null;
    }
    final secondary =
        _normalizeHexColor(brandingSecondarySeedColorController.text);
    if (secondary == null) {
      remoteErrorStreamValue.addValue(
        'Cor secundaria invalida. Use formato #RRGGBB.',
      );
      return null;
    }

    return TenantAdminBrandingUpdateInput(
      tenantName: tenantName,
      brightnessDefault: brandingBrightnessStreamValue.value,
      primarySeedColor: primary,
      secondarySeedColor: secondary,
      lightLogoUpload: lightLogoUpload,
      darkLogoUpload: darkLogoUpload,
      lightIconUpload: lightIconUpload,
      darkIconUpload: darkIconUpload,
      pwaIconUpload: pwaIconUpload,
    );
  }

  void _applyFirebaseSettings(TenantAdminFirebaseSettings settings) {
    firebaseApiKeyController.text = settings.apiKey;
    firebaseAppIdController.text = settings.appId;
    firebaseProjectIdController.text = settings.projectId;
    firebaseMessagingSenderIdController.text = settings.messagingSenderId;
    firebaseStorageBucketController.text = settings.storageBucket;
  }

  void _applyPushSettings(TenantAdminPushSettings settings) {
    pushMaxTtlDaysController.text = '${settings.maxTtlDays}';
    pushMaxPerMinuteController.text = '${settings.maxPerMinute}';
    pushMaxPerHourController.text = '${settings.maxPerHour}';
  }

  void _applyAppLinksSettings(TenantAdminAppLinksSettings settings) {
    appLinksSettingsStreamValue.addValue(settings);
    appLinksIosPathsSelectionStreamValue.addValue(
      List<String>.from(settings.iosPaths, growable: false),
    );
    appLinksAndroidPackageNameController.text =
        settings.androidAppIdentifier ?? '';
    appLinksAndroidFingerprintsController.text =
        settings.androidSha256CertFingerprints.join(', ');
    appLinksIosTeamIdController.text = settings.iosTeamId ?? '';
    appLinksIosBundleIdController.text = settings.iosBundleId ?? '';
  }

  void _applyBrandingSettings(TenantAdminBrandingSettings settings) {
    final cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
    if (settings.tenantName.trim().isNotEmpty) {
      brandingTenantNameController.text = settings.tenantName.trim();
    }
    brandingBrightnessStreamValue.addValue(settings.brightnessDefault);
    brandingPrimarySeedColorController.text = settings.primarySeedColor;
    brandingSecondarySeedColorController.text = settings.secondarySeedColor;
    brandingLightLogoUrlStreamValue.addValue(
      _withCacheBust(
        _tenantScopedAssetUrl('logo-light.png') ?? settings.lightLogoUrl,
        cacheBuster,
      ),
    );
    brandingDarkLogoUrlStreamValue.addValue(
      _withCacheBust(
        _tenantScopedAssetUrl('logo-dark.png') ?? settings.darkLogoUrl,
        cacheBuster,
      ),
    );
    brandingLightIconUrlStreamValue.addValue(
      _withCacheBust(
        _tenantScopedAssetUrl('icon-light.png') ?? settings.lightIconUrl,
        cacheBuster,
      ),
    );
    brandingDarkIconUrlStreamValue.addValue(
      _withCacheBust(
        _tenantScopedAssetUrl('icon-dark.png') ?? settings.darkIconUrl,
        cacheBuster,
      ),
    );
    brandingPwaIconUrlStreamValue.addValue(
      _withCacheBust(
        _tenantScopedAssetUrl('icon/icon-512x512.png') ?? settings.pwaIconUrl,
        cacheBuster,
      ),
    );

    clearBrandingFile(TenantAdminBrandingAssetSlot.lightLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.lightIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.pwaIcon);
  }

  void _applyMapUiSettings(TenantAdminMapUiSettings settings) {
    _mapUiSettings = settings;
    mapUiSettingsStreamValue.addValue(settings);
    final defaultOrigin = settings.defaultOrigin;
    if (defaultOrigin == null) {
      mapDefaultOriginLatitudeController.clear();
      mapDefaultOriginLongitudeController.clear();
      mapDefaultOriginLabelController.clear();
      return;
    }

    mapDefaultOriginLatitudeController.text =
        defaultOrigin.lat.toStringAsFixed(6);
    mapDefaultOriginLongitudeController.text =
        defaultOrigin.lng.toStringAsFixed(6);
    mapDefaultOriginLabelController.text = defaultOrigin.label ?? '';
  }

  Future<Map<String, List<TenantAdminTaxonomyTermDefinition>>>
      _loadTermsByTaxonomySlug({
    required List<TenantAdminTaxonomyDefinition> taxonomies,
  }) async {
    final taxonomyRepo = _taxonomiesRepository;
    if (taxonomyRepo == null) {
      return const <String, List<TenantAdminTaxonomyTermDefinition>>{};
    }
    final entries =
        <MapEntry<String, List<TenantAdminTaxonomyTermDefinition>>>[];
    for (final taxonomy in taxonomies) {
      await taxonomyRepo.loadAllTerms(taxonomyId: taxonomy.id);
      final terms = taxonomyRepo.termsStreamValue.value ??
          const <TenantAdminTaxonomyTermDefinition>[];
      entries.add(
        MapEntry<String, List<TenantAdminTaxonomyTermDefinition>>(
          taxonomy.slug,
          terms,
        ),
      );
    }
    return {
      for (final entry in entries) entry.key: entry.value,
    };
  }

  TenantAdminMapFilterRuleCatalog _buildMapFilterRuleCatalog({
    required List<TenantAdminProfileTypeDefinition> accountTypes,
    required List<TenantAdminStaticProfileTypeDefinition> staticTypes,
    required List<TenantAdminTaxonomyDefinition> taxonomies,
    required Map<String, List<TenantAdminTaxonomyTermDefinition>>
        termsByTaxonomySlug,
  }) {
    final accountTypeOptions = accountTypes
        .where((item) => item.type.trim().isNotEmpty)
        .map(
          (item) => TenantAdminMapFilterTypeOption(
            slug: item.type.trim().toLowerCase(),
            label: item.label.trim().isEmpty ? item.type : item.label.trim(),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.label.compareTo(right.label));

    final staticTypeOptions = staticTypes
        .where((item) => item.type.trim().isNotEmpty)
        .map(
          (item) => TenantAdminMapFilterTypeOption(
            slug: item.type.trim().toLowerCase(),
            label: item.label.trim().isEmpty ? item.type : item.label.trim(),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.label.compareTo(right.label));

    final taxonomyBySource = <TenantAdminMapFilterSource,
        List<TenantAdminMapFilterTaxonomyTermOption>>{
      TenantAdminMapFilterSource.accountProfile:
          <TenantAdminMapFilterTaxonomyTermOption>[],
      TenantAdminMapFilterSource.staticAsset:
          <TenantAdminMapFilterTaxonomyTermOption>[],
      TenantAdminMapFilterSource.event:
          <TenantAdminMapFilterTaxonomyTermOption>[],
    };

    for (final taxonomy in taxonomies) {
      final taxonomySlug = taxonomy.slug.trim().toLowerCase();
      if (taxonomySlug.isEmpty) {
        continue;
      }
      final taxonomyLabel =
          taxonomy.name.trim().isEmpty ? taxonomySlug : taxonomy.name.trim();
      final terms = termsByTaxonomySlug[taxonomy.slug] ?? const [];
      for (final term in terms) {
        final termSlug = term.slug.trim().toLowerCase();
        if (termSlug.isEmpty) {
          continue;
        }
        final option = TenantAdminMapFilterTaxonomyTermOption(
          token: '$taxonomySlug:$termSlug',
          label: term.name.trim().isEmpty ? term.slug : term.name.trim(),
          taxonomySlug: taxonomySlug,
          taxonomyLabel: taxonomyLabel,
        );
        if (taxonomy.appliesToTarget('account_profile')) {
          taxonomyBySource[TenantAdminMapFilterSource.accountProfile]!
              .add(option);
        }
        if (taxonomy.appliesToTarget('static_asset')) {
          taxonomyBySource[TenantAdminMapFilterSource.staticAsset]!.add(option);
        }
        if (taxonomy.appliesToTarget('event')) {
          taxonomyBySource[TenantAdminMapFilterSource.event]!.add(option);
        }
      }
    }

    for (final source in taxonomyBySource.keys) {
      taxonomyBySource[source] =
          List<TenantAdminMapFilterTaxonomyTermOption>.from(
        taxonomyBySource[source]!,
      )..sort((left, right) {
              final group = left.taxonomyLabel.compareTo(right.taxonomyLabel);
              if (group != 0) {
                return group;
              }
              return left.label.compareTo(right.label);
            });
    }

    return TenantAdminMapFilterRuleCatalog(
      typesBySource: {
        TenantAdminMapFilterSource.accountProfile:
            List<TenantAdminMapFilterTypeOption>.unmodifiable(
          accountTypeOptions,
        ),
        TenantAdminMapFilterSource.staticAsset:
            List<TenantAdminMapFilterTypeOption>.unmodifiable(
          staticTypeOptions,
        ),
        TenantAdminMapFilterSource.event:
            const <TenantAdminMapFilterTypeOption>[],
      },
      taxonomyTermsBySource: {
        for (final entry in taxonomyBySource.entries)
          entry.key: List<TenantAdminMapFilterTaxonomyTermOption>.unmodifiable(
            entry.value,
          ),
      },
    );
  }

  TenantAdminMapFilterCatalogItem? _mapFilterAt(int index) {
    if (index < 0 || index >= _mapUiSettings.filters.length) {
      return null;
    }
    return _mapUiSettings.filters[index];
  }

  void _replaceMapFilters(List<TenantAdminMapFilterCatalogItem> nextFilters) {
    final nextSettings = _mapUiSettings.applyFilters(nextFilters);
    _applyMapUiSettings(nextSettings);
  }

  String _buildMapFilterDefaultKey(
    int sequence,
    List<TenantAdminMapFilterCatalogItem> existing,
  ) {
    final existingKeys = existing.map((item) => item.key).toSet();
    var attempt = sequence;
    while (attempt < 999) {
      final candidate = 'filter_$attempt';
      if (!existingKeys.contains(candidate)) {
        return candidate;
      }
      attempt += 1;
    }
    return 'filter_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _normalizeMapFilterKey(String raw) {
    var normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '-');
    normalized = normalized.replaceAll(RegExp(r'-{2,}'), '-');
    normalized = normalized.replaceAll(RegExp(r'^[-_]+|[-_]+$'), '');
    if (normalized.length > _mapFilterKeyMaxLength) {
      normalized = normalized.substring(0, _mapFilterKeyMaxLength);
      normalized = normalized.replaceAll(RegExp(r'^[-_]+|[-_]+$'), '');
    }
    return normalized;
  }

  void _resetMapUiDraft() {
    _mapUiSettings = TenantAdminMapUiSettings.empty();
    mapUiSettingsStreamValue.addValue(TenantAdminMapUiSettings.empty());
    mapFilterRuleCatalogStreamValue
        .addValue(const TenantAdminMapFilterRuleCatalog.empty());
    mapFilterRuleCatalogLoadingStreamValue.addValue(false);
    mapUiSubmittingStreamValue.addValue(false);
    mapDefaultOriginLatitudeController.clear();
    mapDefaultOriginLongitudeController.clear();
    mapDefaultOriginLabelController.clear();
  }

  Future<void> _refreshAppDataSnapshot() async {
    try {
      await _appDataRepository.init();
    } on Object catch (error) {
      debugPrint(
        'TenantAdminSettingsController._refreshAppDataSnapshot failed: $error',
      );
    }
  }

  List<String> _parseCsv(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _parseDelimitedList(String raw) {
    return raw
        .split(RegExp(r'[\n,;]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String? _normalizeOptionalText(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    return value;
  }

  bool _isValidAndroidPackageName(String raw) {
    final pattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');
    return pattern.hasMatch(raw);
  }

  bool _isValidIosBundleId(String raw) {
    final pattern = RegExp(r'^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$');
    return pattern.hasMatch(raw);
  }

  bool _isValidIosTeamId(String raw) {
    final pattern = RegExp(r'^[A-Z0-9]{10}$');
    return pattern.hasMatch(raw.toUpperCase());
  }

  bool _isValidSha256Fingerprint(String raw) {
    final pattern = RegExp(r'^([A-F0-9]{2}:){31}[A-F0-9]{2}$');
    return pattern.hasMatch(raw);
  }

  int? _parsePositiveInt(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  String? _normalizeHexColor(String raw) {
    final value = raw.trim();
    final regex = RegExp(r'^#([a-fA-F0-9]{6})$');
    if (!regex.hasMatch(value)) {
      return null;
    }
    return value.toUpperCase();
  }

  String? _withCacheBust(String? raw, String cacheBuster) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }
    final query = Map<String, String>.from(uri.queryParameters);
    query['v'] = cacheBuster;
    return uri.replace(queryParameters: query).toString();
  }

  void _reportSuccess(String message) {
    remoteErrorStreamValue.addValue(null);
    remoteSuccessStreamValue.addValue(message);
  }

  String? _normalizeTenantDomain(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final hasExplicitScheme = trimmed.contains('://');
    final uri = Uri.tryParse(hasExplicitScheme ? trimmed : 'https://$trimmed');
    if (uri != null && uri.host.trim().isNotEmpty) {
      final host = uri.host.trim().toLowerCase();
      if (hasExplicitScheme) {
        final scheme = uri.scheme.toLowerCase();
        if (scheme != 'http' && scheme != 'https') {
          return null;
        }
        return Uri(
          scheme: scheme,
          host: host,
          port: uri.hasPort ? uri.port : null,
        ).toString();
      }
      if (uri.hasPort) {
        return '$host:${uri.port}';
      }
      return host;
    }
    return trimmed;
  }

  String? _tenantScopedAssetUrl(String assetName) {
    final selected = _tenantScope?.selectedTenantDomain?.trim();
    if (selected == null || selected.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(
      selected.contains('://') ? selected : 'https://$selected',
    );
    if (uri == null || uri.host.trim().isEmpty) {
      return null;
    }
    final base = Uri(
      scheme: uri.scheme.isEmpty ? 'https' : uri.scheme,
      host: uri.host.trim(),
      port: uri.hasPort ? uri.port : null,
      path: '/$assetName',
    );
    return base.toString();
  }

  @override
  void onDispose() {
    isRemoteLoadingStreamValue.dispose();
    remoteErrorStreamValue.dispose();
    remoteSuccessStreamValue.dispose();
    mapUiSubmittingStreamValue.dispose();
    mapUiSettingsStreamValue.dispose();
    appLinksSubmittingStreamValue.dispose();
    appLinksSettingsStreamValue.dispose();
    appLinksIosPathsSelectionStreamValue.dispose();
    mapFilterRuleCatalogStreamValue.dispose();
    mapFilterRuleCatalogLoadingStreamValue.dispose();
    firebaseSubmittingStreamValue.dispose();
    pushSubmittingStreamValue.dispose();
    telemetrySubmittingStreamValue.dispose();
    brandingSubmittingStreamValue.dispose();
    brandingBrightnessStreamValue.dispose();
    brandingLightLogoFileStreamValue.dispose();
    brandingDarkLogoFileStreamValue.dispose();
    brandingLightIconFileStreamValue.dispose();
    brandingDarkIconFileStreamValue.dispose();
    brandingPwaIconFileStreamValue.dispose();
    brandingLightLogoUrlStreamValue.dispose();
    brandingDarkLogoUrlStreamValue.dispose();
    brandingLightIconUrlStreamValue.dispose();
    brandingDarkIconUrlStreamValue.dispose();
    brandingPwaIconUrlStreamValue.dispose();
    telemetrySnapshotStreamValue.dispose();
    selectedTelemetryTypeStreamValue.dispose();
    telemetryTrackAllStreamValue.dispose();
    firebaseApiKeyController.dispose();
    firebaseAppIdController.dispose();
    firebaseProjectIdController.dispose();
    firebaseMessagingSenderIdController.dispose();
    firebaseStorageBucketController.dispose();
    pushMaxTtlDaysController.dispose();
    pushMaxPerMinuteController.dispose();
    pushMaxPerHourController.dispose();
    telemetryEventsController.dispose();
    telemetryTokenController.dispose();
    telemetryUrlController.dispose();
    brandingTenantNameController.dispose();
    brandingPrimarySeedColorController.dispose();
    brandingSecondarySeedColorController.dispose();
    mapDefaultOriginLatitudeController.dispose();
    mapDefaultOriginLongitudeController.dispose();
    mapDefaultOriginLabelController.dispose();
    appLinksAndroidPackageNameController.dispose();
    appLinksAndroidFingerprintsController.dispose();
    appLinksIosTeamIdController.dispose();
    appLinksIosBundleIdController.dispose();
    _tenantScopeSubscription?.cancel();
    _brandingSubscription?.cancel();
    _locationSelectionSubscription?.cancel();
  }
}
