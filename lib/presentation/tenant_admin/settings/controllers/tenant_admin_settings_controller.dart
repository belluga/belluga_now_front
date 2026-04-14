export 'tenant_admin_branding_asset_slot.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
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
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_app_link_path_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_team_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_positive_int_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_map_filter_rule_values.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_branding_asset_slot.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_favicon_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';

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
    TenantAdminFaviconIngestionService? faviconIngestionService,
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
                : TenantAdminImageIngestionService()),
        _faviconIngestionService = faviconIngestionService ??
            (GetIt.I.isRegistered<TenantAdminFaviconIngestionService>()
                ? GetIt.I.get<TenantAdminFaviconIngestionService>()
                : TenantAdminFaviconIngestionService()) {
    _bindMaxRadiusStream();
  }

  final AppDataRepositoryContract _appDataRepository;
  final TenantAdminSettingsRepositoryContract _settingsRepository;
  final TenantAdminAccountProfilesRepositoryContract?
      _accountProfilesRepository;
  final TenantAdminStaticAssetsRepositoryContract? _staticAssetsRepository;
  final TenantAdminTaxonomiesRepositoryContract? _taxonomiesRepository;
  final TenantAdminTenantScopeContract? _tenantScope;
  final TenantAdminLocationSelectionContract _locationSelectionService;
  final TenantAdminImageIngestionService _imageIngestionService;
  final TenantAdminFaviconIngestionService _faviconIngestionService;

  static const List<String> telemetryTypes = [
    'mixpanel',
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
  final StreamValue<bool> domainsSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
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
  final StreamValue<bool> resendEmailSubmittingStreamValue =
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
  final StreamValue<TenantAdminMediaUpload?> brandingFaviconUploadStreamValue =
      StreamValue<TenantAdminMediaUpload?>();

  final StreamValue<String?> brandingLightLogoUrlStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> brandingDarkLogoUrlStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> brandingLightIconUrlStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> brandingDarkIconUrlStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> brandingFaviconUrlStreamValue =
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
  final TextEditingController resendEmailTokenController =
      TextEditingController();
  final TextEditingController resendEmailFromController =
      TextEditingController();
  final TextEditingController resendEmailToController = TextEditingController();
  final TextEditingController resendEmailCcController = TextEditingController();
  final TextEditingController resendEmailBccController =
      TextEditingController();
  final TextEditingController resendEmailReplyToController =
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
  final TextEditingController domainPathController = TextEditingController();
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
  StreamSubscription<DistanceInMetersValue>? _maxRadiusSubscription;
  StreamSubscription<TenantAdminBrandingSettings?>? _brandingSubscription;
  StreamSubscription<TenantAdminLocation?>? _locationSelectionSubscription;
  TenantAdminMapUiSettings _mapUiSettings = TenantAdminMapUiSettings.empty();
  bool _localPreferencesFlowBound = false;
  final StreamValue<double> maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: 50000);

  AppData get appData => _appDataRepository.appData;
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      _appDataRepository.themeModeStreamValue;
  StreamValue<TenantAdminBrandingSettings?> get brandingSettingsStreamValue =>
      _settingsRepository.brandingSettingsStreamValue;
  StreamValue<List<TenantAdminDomainEntry>> get domainsStreamValue =>
      _settingsRepository.domainsStreamValue;
  StreamValue<bool> get domainsPageLoadingStreamValue =>
      _settingsRepository.isDomainsPageLoadingStreamValue;
  StreamValue<bool> get hasMoreDomainsStreamValue =>
      _settingsRepository.hasMoreDomainsStreamValue;
  List<String> get appLinksCanonicalIosPaths =>
      TenantAdminAppLinksSettings.canonicalIosPaths;

  void _bindMaxRadiusStream() {
    _maxRadiusSubscription?.cancel();
    maxRadiusMetersStreamValue
        .addValue(_appDataRepository.maxRadiusMeters.value);
    _maxRadiusSubscription =
        _appDataRepository.maxRadiusMetersStreamValue.stream.listen((value) {
      maxRadiusMetersStreamValue.addValue(value.value);
    });
  }

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
    return _appDataRepository.setThemeMode(AppThemeModeValue.fromRaw(mode));
  }

  Future<void> updateMaxRadiusMeters(double meters) {
    return _appDataRepository
        .setMaxRadiusMeters(_distanceInMetersValue(meters));
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
        final resendEmailSettings =
            await _settingsRepository.fetchResendEmailSettings();
        _applyResendEmailSettings(resendEmailSettings);
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

  Future<void> loadDomains({bool clearMessages = true}) async {
    if (isRemoteLoadingStreamValue.value) {
      return;
    }
    isRemoteLoadingStreamValue.addValue(true);
    if (clearMessages) {
      clearStatusMessages();
    } else {
      remoteErrorStreamValue.addValue(null);
    }
    try {
      await _settingsRepository.loadDomains();
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      isRemoteLoadingStreamValue.addValue(false);
    }
  }

  Future<void> loadNextDomainsPage() async {
    if (domainsPageLoadingStreamValue.value ||
        isRemoteLoadingStreamValue.value ||
        !hasMoreDomainsStreamValue.value) {
      return;
    }
    remoteErrorStreamValue.addValue(null);
    try {
      await _settingsRepository.loadMoreDomains();
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    }
  }

  Future<void> createDomain() async {
    final normalizedPath = _normalizeTenantWebDomainPath(
      domainPathController.text,
    );
    if (normalizedPath == null || normalizedPath.isEmpty) {
      remoteSuccessStreamValue.addValue(null);
      remoteErrorStreamValue.addValue('Informe um domínio web válido.');
      return;
    }

    domainsSubmittingStreamValue.addValue(true);
    remoteErrorStreamValue.addValue(null);
    try {
      await _settingsRepository.createDomain(
        path: _requiredTextValue(normalizedPath),
      );
      domainPathController.clear();
      await _refreshAppDataSnapshot();
      await _settingsRepository.loadDomains();
      _reportSuccess('Domínio adicionado com sucesso.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      domainsSubmittingStreamValue.addValue(false);
    }
  }

  Future<void> deleteDomain(TenantAdminDomainEntry domain) async {
    if (!canDeleteDomain(domain)) {
      remoteSuccessStreamValue.addValue(null);
      remoteErrorStreamValue.addValue(
        'Acesse outro domínio ativo para remover o domínio atual.',
      );
      return;
    }

    domainsSubmittingStreamValue.addValue(true);
    remoteErrorStreamValue.addValue(null);
    try {
      await _settingsRepository.deleteDomain(_requiredTextValue(domain.id));
      await _refreshAppDataSnapshot();
      await _settingsRepository.loadDomains();
      _reportSuccess('Domínio removido com sucesso.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      domainsSubmittingStreamValue.addValue(false);
    }
  }

  bool isCurrentTenantDomain(TenantAdminDomainEntry domain) {
    return _domainIdentity(_tenantScope?.selectedTenantDomain) ==
        _domainIdentity(domain.path);
  }

  bool canDeleteDomain(TenantAdminDomainEntry domain) {
    return domain.isActive && !isCurrentTenantDomain(domain);
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
    return tenantAdminLocationFromRaw(latitude: lat, longitude: lng);
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
          lat: _latitudeValue(latitude),
          lng: _longitudeValue(longitude),
          label: label.isEmpty ? null : _optionalTextValue(label),
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
        keyValue: _tokenValue(defaultKey),
        labelValue: _requiredTextValue('Filtro ${nextIndex.toString()}'),
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
    current[index] = item.copyWith(
      keyValue: _tokenValue(normalized),
    );
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
    current[index] = item.copyWith(
      labelValue: _requiredTextValue(label),
    );
    _replaceMapFilters(current);
    remoteErrorStreamValue.addValue(null);
  }

  void updateMapFilterItemRule(
    int index,
    TenantAdminMapFilterCatalogItem nextItem,
  ) {
    final currentItem = _mapFilterAt(index);
    if (currentItem == null) {
      return;
    }
    final source = nextItem.query.source;
    if (source == null) {
      remoteErrorStreamValue.addValue(
        'Selecione a origem do filtro (Conta, Asset ou Evento).',
      );
      return;
    }
    final sanitized = TenantAdminMapFilterQuery(
      source: source,
      typeValues: nextItem.query.types
          .map((entry) => _tokenValue(entry.value))
          .toList(),
      taxonomyValues: nextItem.query.taxonomy
          .map((entry) => _tokenValue(entry.value))
          .toList(),
    );

    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    current[index] = currentItem.copyWith(
      query: sanitized,
    );
    _replaceMapFilters(current);
    remoteErrorStreamValue.addValue(null);
  }

  void updateMapFilterItemVisual(
    int index,
    TenantAdminMapFilterCatalogItem nextItem,
  ) {
    final currentItem = _mapFilterAt(index);
    if (currentItem == null) {
      return;
    }

    final imageUri = _sanitizeMapFilterImageUri(nextItem.imageUri);
    if (nextItem.imageUri?.trim().isNotEmpty == true && imageUri == null) {
      remoteErrorStreamValue.addValue(
        'URL de imagem inválida. Use formato http/https.',
      );
      return;
    }

    final overrideMarker = nextItem.overrideMarker;
    final markerOverride = _sanitizeMapFilterMarkerOverride(
      overrideMarker: overrideMarker,
      markerOverride: nextItem.markerOverride,
      imageUri: imageUri,
    );
    if (overrideMarker && markerOverride == null) {
      remoteErrorStreamValue.addValue(
        'Override do marcador inválido. Em modo ícone, informe ícone e cor (#RRGGBB). Em modo imagem, defina uma imagem válida.',
      );
      return;
    }

    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    final imageUriValue = imageUri == null
        ? null
        : (TenantAdminOptionalUrlValue()..parse(imageUri));
    current[index] = currentItem.copyWith(
      imageUriValue: imageUriValue,
      clearImageUriValue: TenantAdminFlagValue(imageUri == null),
      overrideMarkerValue: TenantAdminFlagValue(overrideMarker),
      markerOverride: markerOverride,
      clearMarkerOverrideValue: TenantAdminFlagValue(!overrideMarker),
    );
    _replaceMapFilters(current);
    remoteErrorStreamValue.addValue(null);
  }

  void clearMapFilterItemImage(int index) {
    final item = _mapFilterAt(index);
    if (item == null) {
      return;
    }
    final shouldDisableImageOverride = item.overrideMarker &&
        item.markerOverride?.mode ==
            TenantAdminMapFilterMarkerOverrideMode.image;
    final current = List<TenantAdminMapFilterCatalogItem>.from(
      _mapUiSettings.filters,
    );
    current[index] = item.copyWith(
      clearImageUriValue: TenantAdminFlagValue(true),
      overrideMarkerValue: TenantAdminFlagValue(
          shouldDisableImageOverride ? false : item.overrideMarker),
      clearMarkerOverrideValue:
          TenantAdminFlagValue(shouldDisableImageOverride),
    );
    _replaceMapFilters(current);
    if (shouldDisableImageOverride) {
      _reportSuccess(
        'Imagem removida. Override de marcador em modo imagem foi desativado.',
      );
    }
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
        key: _tokenValue(key),
        upload: upload,
      );
      final uploadedImageUriValue = TenantAdminOptionalUrlValue();
      uploadedImageUriValue.parse(imageUri);
      final current = List<TenantAdminMapFilterCatalogItem>.from(
        _mapUiSettings.filters,
      );
      current[index] = item.copyWith(
        keyValue: _tokenValue(key),
        imageUriValue: uploadedImageUriValue,
        markerOverride: item.overrideMarker &&
                item.markerOverride?.mode ==
                    TenantAdminMapFilterMarkerOverrideMode.image
            ? TenantAdminMapFilterMarkerOverride.image(
                imageUriValue: uploadedImageUriValue,
              )
            : item.markerOverride,
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

  Future<void> saveResendEmailSettings() async {
    final parsed = _buildResendEmailSettings();
    if (parsed == null) {
      return;
    }

    resendEmailSubmittingStreamValue.addValue(true);
    try {
      final updated = await _settingsRepository.updateResendEmailSettings(
        settings: parsed,
      );
      _applyResendEmailSettings(updated);
      _reportSuccess('Resend atualizado com sucesso.');
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      resendEmailSubmittingStreamValue.addValue(false);
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
    required TenantAdminMediaUpload? faviconUpload,
    required TenantAdminMediaUpload? pwaIconUpload,
  }) async {
    final input = _buildBrandingUpdateInput(
      lightLogoUpload: lightLogoUpload,
      darkLogoUpload: darkLogoUpload,
      lightIconUpload: lightIconUpload,
      darkIconUpload: darkIconUpload,
      faviconUpload: faviconUpload,
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

  Future<TenantAdminMediaUpload?> pickBrandingFaviconFromDevice() {
    return _faviconIngestionService.pickFromDevice();
  }

  Future<XFile> fetchBrandingImageFromUrlForCrop({
    required String imageUrl,
  }) {
    return _imageIngestionService.fetchFromUrlForCrop(imageUrl: imageUrl);
  }

  Future<TenantAdminMediaUpload> fetchBrandingFaviconFromUrl({
    required String faviconUrl,
  }) {
    return _faviconIngestionService.fetchFromUrl(faviconUrl: faviconUrl);
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

  void updateBrandingFaviconUpload(TenantAdminMediaUpload? upload) {
    brandingFaviconUploadStreamValue.addValue(upload);
    if (upload != null) {
      brandingFaviconUrlStreamValue.addValue(null);
    }
  }

  void clearBrandingFaviconUpload() {
    brandingFaviconUploadStreamValue.addValue(null);
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
          type: _tokenValue(type),
          trackAll: _booleanValue(trackAll),
          eventValues: events.map(_tokenValue).toList(growable: false),
          token: telemetryTokenController.text.trim().isEmpty
              ? null
              : _optionalTextValue(telemetryTokenController.text.trim()),
          url: telemetryUrlController.text.trim().isEmpty
              ? null
              : _optionalUrlValue(telemetryUrlController.text.trim()),
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
        type: _tokenValue(type),
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
    _resetResendEmailDraft();
    clearBrandingFile(TenantAdminBrandingAssetSlot.lightLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.lightIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.pwaIcon);
    clearBrandingFaviconUpload();
    _seedFirebaseAndPushFromSnapshot();
    _clearBrandingDraftForRemoteLoad();
    _resetDomainsDraft();
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
    brandingFaviconUrlStreamValue.addValue(null);
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

  void _resetResendEmailDraft() {
    resendEmailSubmittingStreamValue.addValue(false);
    resendEmailTokenController.clear();
    resendEmailFromController.clear();
    resendEmailToController.clear();
    resendEmailCcController.clear();
    resendEmailBccController.clear();
    resendEmailReplyToController.clear();
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
      apiKey: _requiredTextValue(apiKey),
      appId: _requiredTextValue(appId),
      projectId: _requiredTextValue(projectId),
      messagingSenderId: _requiredTextValue(senderId),
      storageBucket: _requiredTextValue(storageBucket),
    );
  }

  TenantAdminResendEmailSettings? _buildResendEmailSettings() {
    final token = _normalizeOptionalText(resendEmailTokenController.text);
    if (token == null) {
      remoteErrorStreamValue.addValue(
        'Token do Resend é obrigatório.',
      );
      return null;
    }

    final from = _normalizeOptionalText(resendEmailFromController.text);
    if (from == null) {
      remoteErrorStreamValue.addValue(
        'Remetente do Resend é obrigatório.',
      );
      return null;
    }
    if (!_isValidResendSender(from)) {
      remoteErrorStreamValue.addValue(
        'Remetente inválido. Use "Nome <email@dominio.com>" ou apenas "email@dominio.com".',
      );
      return null;
    }

    final to = _parseDelimitedList(resendEmailToController.text);
    if (to.isEmpty) {
      remoteErrorStreamValue.addValue(
        'Informe ao menos um destinatário em To.',
      );
      return null;
    }
    if (to.length > 50) {
      remoteErrorStreamValue.addValue(
        'O campo To aceita no máximo 50 destinatários.',
      );
      return null;
    }
    final invalidTo = to.firstWhere(
      (entry) => !_isValidEmailAddress(entry),
      orElse: () => '',
    );
    if (invalidTo.isNotEmpty) {
      remoteErrorStreamValue.addValue(
        'O campo To deve conter apenas e-mails válidos.',
      );
      return null;
    }

    final cc = _parseDelimitedList(resendEmailCcController.text);
    if (cc.any((entry) => !_isValidEmailAddress(entry))) {
      remoteErrorStreamValue.addValue(
        'O campo Cc deve conter apenas e-mails válidos.',
      );
      return null;
    }

    final bcc = _parseDelimitedList(resendEmailBccController.text);
    if (bcc.any((entry) => !_isValidEmailAddress(entry))) {
      remoteErrorStreamValue.addValue(
        'O campo Bcc deve conter apenas e-mails válidos.',
      );
      return null;
    }

    final replyTo = _parseDelimitedList(resendEmailReplyToController.text);
    if (replyTo.any((entry) => !_isValidEmailAddress(entry))) {
      remoteErrorStreamValue.addValue(
        'O campo Reply-To deve conter apenas e-mails válidos.',
      );
      return null;
    }

    return TenantAdminResendEmailSettings(
      token: _optionalTextValue(token),
      from: _optionalTextValue(from),
      toRecipients: _resendEmailRecipients(to),
      ccRecipients: _resendEmailRecipients(cc),
      bccRecipients: _resendEmailRecipients(bcc),
      replyToRecipients: _resendEmailRecipients(replyTo),
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
      maxTtlDaysValue: _positiveIntValue(ttlDays),
      maxPerMinuteValue: _positiveIntValue(maxPerMinute),
      maxPerHourValue: _positiveIntValue(maxPerHour),
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
        androidAppIdentifier: _androidAppIdentifierValue(androidPackageName),
        androidSha256CertFingerprintValues:
            fingerprints.map(_sha256FingerprintValue).toList(growable: false),
        iosTeamId: iosTeamId == null ? null : _iosTeamIdValue(iosTeamId),
        iosBundleId:
            iosBundleId == null ? null : _iosBundleIdValue(iosBundleId),
        iosPathValues: iosPaths.map(_appLinkPathValue).toList(growable: false),
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
    required TenantAdminMediaUpload? faviconUpload,
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
      tenantName: _requiredTextValue(tenantName),
      brightnessDefault: brandingBrightnessStreamValue.value,
      primarySeedColor: _hexColorValue(primary),
      secondarySeedColor: _hexColorValue(secondary),
      lightLogoUpload: lightLogoUpload,
      darkLogoUpload: darkLogoUpload,
      lightIconUpload: lightIconUpload,
      darkIconUpload: darkIconUpload,
      faviconUpload: faviconUpload,
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

  void _applyResendEmailSettings(TenantAdminResendEmailSettings settings) {
    resendEmailTokenController.text = settings.token ?? '';
    resendEmailFromController.text = settings.from ?? '';
    resendEmailToController.text = _recipientText(settings.to);
    resendEmailCcController.text = _recipientText(settings.cc);
    resendEmailBccController.text = _recipientText(settings.bcc);
    resendEmailReplyToController.text = _recipientText(settings.replyTo);
  }

  TenantAdminResendEmailRecipients _resendEmailRecipients(
    Iterable<String> rawValues,
  ) {
    return TenantAdminResendEmailRecipients(
      rawValues.map(_emailAddressValue),
    );
  }

  EmailAddressValue _emailAddressValue(String raw) {
    final value = EmailAddressValue();
    value.parse(raw);
    return value;
  }

  String _recipientText(TenantAdminResendEmailRecipients recipients) {
    return recipients.values.map((entry) => entry.value).join(', ');
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
    brandingFaviconUrlStreamValue.addValue(
      _withCacheBust(
        _tenantScopedAssetUrl('favicon.ico') ?? settings.faviconUrl,
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
    clearBrandingFaviconUpload();
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
      await taxonomyRepo.loadAllTerms(
          taxonomyId: TenantAdminTaxRepoString.fromRaw(taxonomy.id,
              defaultValue: '', isRequired: true));
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
            slugValue: _tokenValue(item.type.trim().toLowerCase()),
            labelValue: _requiredTextValue(
              item.label.trim().isEmpty ? item.type : item.label.trim(),
            ),
          ),
        )
        .toList(growable: false)
      ..sort((left, right) => left.label.compareTo(right.label));

    final staticTypeOptions = staticTypes
        .where((item) => item.type.trim().isNotEmpty)
        .map(
          (item) => TenantAdminMapFilterTypeOption(
            slugValue: _tokenValue(item.type.trim().toLowerCase()),
            labelValue: _requiredTextValue(
              item.label.trim().isEmpty ? item.type : item.label.trim(),
            ),
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
          tokenValue: _tokenValue('$taxonomySlug:$termSlug'),
          labelValue: _requiredTextValue(
            term.name.trim().isEmpty ? term.slug : term.name.trim(),
          ),
          taxonomySlugValue: _tokenValue(taxonomySlug),
          taxonomyLabelValue: _requiredTextValue(taxonomyLabel),
        );
        if (taxonomy.appliesToAccountProfile()) {
          taxonomyBySource[TenantAdminMapFilterSource.accountProfile]!
              .add(option);
        }
        if (taxonomy.appliesToStaticAsset()) {
          taxonomyBySource[TenantAdminMapFilterSource.staticAsset]!.add(option);
        }
        if (taxonomy.appliesToEvent()) {
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
      typesBySource: TenantAdminMapFilterTypeOptionsBySourceValue({
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
      }),
      taxonomyTermsBySource: TenantAdminMapFilterTaxonomyOptionsBySourceValue({
        for (final entry in taxonomyBySource.entries)
          entry.key: List<TenantAdminMapFilterTaxonomyTermOption>.unmodifiable(
            entry.value,
          ),
      }),
    );
  }

  TenantAdminMapFilterCatalogItem? _mapFilterAt(int index) {
    if (index < 0 || index >= _mapUiSettings.filters.length) {
      return null;
    }
    return _mapUiSettings.filters.elementAt(index);
  }

  void _replaceMapFilters(List<TenantAdminMapFilterCatalogItem> nextFilters) {
    final nextSettings = _mapUiSettings.applyFilters(
      _mapFilterCatalogItems(nextFilters),
    );
    _applyMapUiSettings(nextSettings);
  }

  TenantAdminMapFilterCatalogItems _mapFilterCatalogItems(
    Iterable<TenantAdminMapFilterCatalogItem> items,
  ) {
    final collection = TenantAdminMapFilterCatalogItems();
    for (final item in items) {
      collection.add(item);
    }
    return collection;
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

  String? _sanitizeMapFilterImageUri(String? rawImageUri) {
    final normalized = rawImageUri?.trim() ?? '';
    if (normalized.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.trim().isEmpty) {
      return null;
    }
    return normalized;
  }

  TenantAdminMapFilterMarkerOverride? _sanitizeMapFilterMarkerOverride({
    required bool overrideMarker,
    required TenantAdminMapFilterMarkerOverride? markerOverride,
    required String? imageUri,
  }) {
    if (!overrideMarker) {
      return null;
    }

    if (markerOverride == null) {
      return null;
    }

    if (markerOverride.mode == TenantAdminMapFilterMarkerOverrideMode.icon) {
      if (!markerOverride.isValid ||
          markerOverride.iconValue == null ||
          markerOverride.colorValue == null ||
          markerOverride.iconColorValue == null) {
        return null;
      }

      return TenantAdminMapFilterMarkerOverride.icon(
        iconValue: markerOverride.iconValue!,
        colorValue: markerOverride.colorValue!,
        iconColorValue: markerOverride.iconColorValue!,
      );
    }

    if (imageUri == null || imageUri.isEmpty) {
      return null;
    }

    final imageUriValue = TenantAdminOptionalUrlValue();
    try {
      imageUriValue.parse(imageUri);
    } on Object {
      return null;
    }

    return TenantAdminMapFilterMarkerOverride.image(
      imageUriValue: imageUriValue,
    );
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

  void _resetDomainsDraft() {
    _settingsRepository.resetDomainsState();
    domainsSubmittingStreamValue.addValue(false);
    domainPathController.clear();
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

  TenantAdminLowercaseTokenValue _tokenValue(String raw) {
    final value = TenantAdminLowercaseTokenValue();
    value.parse(raw);
    return value;
  }

  TenantAdminBooleanValue _booleanValue(bool raw) {
    final value = TenantAdminBooleanValue();
    value.parse(raw.toString());
    return value;
  }

  TenantAdminRequiredTextValue _requiredTextValue(String raw) {
    final value = TenantAdminRequiredTextValue();
    value.parse(raw);
    return value;
  }

  TenantAdminOptionalTextValue _optionalTextValue(String raw) {
    final value = TenantAdminOptionalTextValue();
    value.parse(raw);
    return value;
  }

  TenantAdminOptionalUrlValue _optionalUrlValue(String raw) {
    final value = TenantAdminOptionalUrlValue();
    value.parse(raw);
    return value;
  }

  TenantAdminHexColorValue _hexColorValue(String raw) {
    final value = TenantAdminHexColorValue();
    value.parse(raw);
    return value;
  }

  TenantAdminAndroidAppIdentifierValue _androidAppIdentifierValue(String raw) {
    final value = TenantAdminAndroidAppIdentifierValue();
    value.parse(raw);
    return value;
  }

  TenantAdminIosTeamIdValue _iosTeamIdValue(String raw) {
    final value = TenantAdminIosTeamIdValue();
    value.parse(raw);
    return value;
  }

  TenantAdminIosBundleIdentifierValue _iosBundleIdValue(String raw) {
    final value = TenantAdminIosBundleIdentifierValue();
    value.parse(raw);
    return value;
  }

  TenantAdminSha256FingerprintValue _sha256FingerprintValue(String raw) {
    final value = TenantAdminSha256FingerprintValue();
    value.parse(raw);
    return value;
  }

  TenantAdminAppLinkPathValue _appLinkPathValue(String raw) {
    final value = TenantAdminAppLinkPathValue();
    value.parse(raw);
    return value;
  }

  LatitudeValue _latitudeValue(double raw) {
    final value = LatitudeValue();
    value.parse(raw.toString());
    return value;
  }

  LongitudeValue _longitudeValue(double raw) {
    final value = LongitudeValue();
    value.parse(raw.toString());
    return value;
  }

  DistanceInMetersValue _distanceInMetersValue(double raw) {
    final value = DistanceInMetersValue();
    value.parse(raw.toString());
    return value;
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

  bool _isValidEmailAddress(String raw) {
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return pattern.hasMatch(raw);
  }

  bool _isValidResendSender(String raw) {
    if (_isValidEmailAddress(raw)) {
      return true;
    }

    final match = RegExp(
      r'^.+<\s*([^<>\s@]+@[^\s@<>]+\.[^\s@<>]+)\s*>$',
    ).firstMatch(raw);
    if (match == null) {
      return false;
    }

    final address = match.group(1)?.trim() ?? '';
    return address.isNotEmpty && _isValidEmailAddress(address);
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

  TenantAdminPositiveIntValue _positiveIntValue(int raw) {
    final value = TenantAdminPositiveIntValue();
    value.parse(raw.toString());
    return value;
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

  String? _normalizeTenantWebDomainPath(String? raw) {
    return _domainIdentity(raw);
  }

  String? _domainIdentity(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    if (parsed == null || parsed.host.trim().isEmpty) {
      return trimmed.toLowerCase();
    }
    final host = parsed.host.trim().toLowerCase();
    if (parsed.hasPort) {
      return '$host:${parsed.port}';
    }
    return host;
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
    domainsSubmittingStreamValue.dispose();
    appLinksSubmittingStreamValue.dispose();
    appLinksSettingsStreamValue.dispose();
    appLinksIosPathsSelectionStreamValue.dispose();
    mapFilterRuleCatalogStreamValue.dispose();
    mapFilterRuleCatalogLoadingStreamValue.dispose();
    firebaseSubmittingStreamValue.dispose();
    resendEmailSubmittingStreamValue.dispose();
    pushSubmittingStreamValue.dispose();
    telemetrySubmittingStreamValue.dispose();
    brandingSubmittingStreamValue.dispose();
    brandingBrightnessStreamValue.dispose();
    brandingLightLogoFileStreamValue.dispose();
    brandingDarkLogoFileStreamValue.dispose();
    brandingLightIconFileStreamValue.dispose();
    brandingDarkIconFileStreamValue.dispose();
    brandingPwaIconFileStreamValue.dispose();
    brandingFaviconUploadStreamValue.dispose();
    brandingLightLogoUrlStreamValue.dispose();
    brandingDarkLogoUrlStreamValue.dispose();
    brandingLightIconUrlStreamValue.dispose();
    brandingDarkIconUrlStreamValue.dispose();
    brandingFaviconUrlStreamValue.dispose();
    brandingPwaIconUrlStreamValue.dispose();
    telemetrySnapshotStreamValue.dispose();
    selectedTelemetryTypeStreamValue.dispose();
    telemetryTrackAllStreamValue.dispose();
    firebaseApiKeyController.dispose();
    firebaseAppIdController.dispose();
    firebaseProjectIdController.dispose();
    firebaseMessagingSenderIdController.dispose();
    firebaseStorageBucketController.dispose();
    resendEmailTokenController.dispose();
    resendEmailFromController.dispose();
    resendEmailToController.dispose();
    resendEmailCcController.dispose();
    resendEmailBccController.dispose();
    resendEmailReplyToController.dispose();
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
    domainPathController.dispose();
    appLinksAndroidPackageNameController.dispose();
    appLinksAndroidFingerprintsController.dispose();
    appLinksIosTeamIdController.dispose();
    appLinksIosBundleIdController.dispose();
    _tenantScopeSubscription?.cancel();
    _maxRadiusSubscription?.cancel();
    _brandingSubscription?.cancel();
    _locationSelectionSubscription?.cancel();
    maxRadiusMetersStreamValue.dispose();
  }
}
