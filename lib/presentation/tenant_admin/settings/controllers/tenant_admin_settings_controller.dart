import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

enum TenantAdminBrandingAssetSlot {
  lightLogo,
  darkLogo,
  lightIcon,
  darkIcon,
  pwaIcon,
}

class TenantAdminSettingsController implements Disposable {
  TenantAdminSettingsController({
    AppDataRepositoryContract? appDataRepository,
    TenantAdminSettingsRepositoryContract? settingsRepository,
    TenantAdminTenantScopeContract? tenantScope,
  })  : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _settingsRepository = settingsRepository ??
            GetIt.I.get<TenantAdminSettingsRepositoryContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null);

  final AppDataRepositoryContract _appDataRepository;
  final TenantAdminSettingsRepositoryContract _settingsRepository;
  final TenantAdminTenantScopeContract? _tenantScope;

  static const List<String> telemetryTypes = [
    'mixpanel',
    'firebase',
    'webhook',
  ];

  final StreamValue<bool> isRemoteLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> remoteErrorStreamValue = StreamValue<String?>();
  final StreamValue<String?> remoteSuccessStreamValue = StreamValue<String?>();

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
    defaultValue: const TenantAdminTelemetrySettingsSnapshot.empty(),
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

  bool _initialized = false;
  String? _initializedTenantDomain;
  StreamSubscription<String?>? _tenantScopeSubscription;

  AppData get appData => _appDataRepository.appData;
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      _appDataRepository.themeModeStreamValue;
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _appDataRepository.maxRadiusMetersStreamValue;

  Future<void> init() async {
    _bindTenantScope();
    final normalizedTenantDomain =
        _normalizeTenantDomain(_tenantScope?.selectedTenantDomain);
    if (_initialized) {
      if (_initializedTenantDomain != normalizedTenantDomain) {
        _initializedTenantDomain = normalizedTenantDomain;
        _resetTenantScopedForms();
        await loadRemoteSettings();
      }
      return;
    }
    _initialized = true;
    _initializedTenantDomain = normalizedTenantDomain;
    _seedFormsFromSnapshot();
    await loadRemoteSettings();
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
          unawaited(loadRemoteSettings());
        }
      },
    );
  }

  Future<void> updateThemeMode(ThemeMode mode) {
    return _appDataRepository.setThemeMode(mode);
  }

  Future<void> updateMaxRadiusMeters(double meters) {
    return _appDataRepository.setMaxRadiusMeters(meters);
  }

  Future<void> loadRemoteSettings() async {
    isRemoteLoadingStreamValue.addValue(true);
    remoteErrorStreamValue.addValue(null);

    try {
      final results = await Future.wait<dynamic>([
        _settingsRepository.fetchFirebaseSettings(),
        _settingsRepository.fetchTelemetrySettings(),
      ]);

      final firebaseSettings = results[0] as TenantAdminFirebaseSettings?;
      final telemetrySnapshot =
          results[1] as TenantAdminTelemetrySettingsSnapshot;

      if (firebaseSettings != null) {
        _applyFirebaseSettings(firebaseSettings);
      }
      telemetrySnapshotStreamValue.addValue(telemetrySnapshot);
      remoteErrorStreamValue.addValue(null);
    } catch (error) {
      remoteErrorStreamValue.addValue(error.toString());
    } finally {
      isRemoteLoadingStreamValue.addValue(false);
    }
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
      final updated = await _settingsRepository.updateBranding(input: input);
      _applyBrandingSettings(updated);
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

  void _seedFormsFromSnapshot() {
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

    brandingTenantNameController.text = appData.nameValue.value;
    final lightScheme = appData.themeDataSettings.lightSchemeData;
    brandingPrimarySeedColorController.text =
        _colorToHex(lightScheme.primarySeedColorValue.value);
    brandingSecondarySeedColorController.text =
        _colorToHex(lightScheme.secondarySeedColorValue.value);
    brandingBrightnessStreamValue.addValue(
        _toBrandingBrightness(appData.themeDataSettings.brightnessDefault));
    brandingLightLogoUrlStreamValue.addValue(
      _tenantScopedAssetUrl('logo-light.png') ??
          appData.mainLogoLightUrl.value?.toString(),
    );
    brandingDarkLogoUrlStreamValue.addValue(
      _tenantScopedAssetUrl('logo-dark.png') ??
          appData.mainLogoDarkUrl.value?.toString(),
    );
    brandingLightIconUrlStreamValue.addValue(
      _tenantScopedAssetUrl('icon-light.png') ??
          appData.mainIconLightUrl.value?.toString(),
    );
    brandingDarkIconUrlStreamValue.addValue(
      _tenantScopedAssetUrl('icon-dark.png') ??
          appData.mainIconDarkUrl.value?.toString(),
    );
    brandingPwaIconUrlStreamValue.addValue(null);
  }

  void _resetTenantScopedForms() {
    clearStatusMessages();
    telemetrySnapshotStreamValue
        .addValue(const TenantAdminTelemetrySettingsSnapshot.empty());
    clearTelemetryForm();
    clearBrandingFile(TenantAdminBrandingAssetSlot.lightLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.lightIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.pwaIcon);
    _seedFormsFromSnapshot();
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
        _tenantScopedAssetUrl('logo-light.png') ??
            appData.mainLogoLightUrl.value?.toString() ??
            settings.lightLogoUrl,
        cacheBuster,
      ),
    );
    brandingDarkLogoUrlStreamValue.addValue(
      _withCacheBust(
        _tenantScopedAssetUrl('logo-dark.png') ??
            appData.mainLogoDarkUrl.value?.toString() ??
            settings.darkLogoUrl,
        cacheBuster,
      ),
    );
    brandingLightIconUrlStreamValue.addValue(
      _withCacheBust(
        _tenantScopedAssetUrl('icon-light.png') ??
            appData.mainIconLightUrl.value?.toString() ??
            settings.lightIconUrl,
        cacheBuster,
      ),
    );
    brandingDarkIconUrlStreamValue.addValue(
      _withCacheBust(
        _tenantScopedAssetUrl('icon-dark.png') ??
            appData.mainIconDarkUrl.value?.toString() ??
            settings.darkIconUrl,
        cacheBuster,
      ),
    );
    brandingPwaIconUrlStreamValue
        .addValue(_withCacheBust(settings.pwaIconUrl, cacheBuster));

    clearBrandingFile(TenantAdminBrandingAssetSlot.lightLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkLogo);
    clearBrandingFile(TenantAdminBrandingAssetSlot.lightIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.darkIcon);
    clearBrandingFile(TenantAdminBrandingAssetSlot.pwaIcon);
  }

  List<String> _parseCsv(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
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

  String _colorToHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  TenantAdminBrandingBrightness _toBrandingBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? TenantAdminBrandingBrightness.dark
        : TenantAdminBrandingBrightness.light;
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
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
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
    _tenantScopeSubscription?.cancel();
  }
}
