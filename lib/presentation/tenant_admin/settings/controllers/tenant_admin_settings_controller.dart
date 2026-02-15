import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

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
  }

  void _resetTenantScopedForms() {
    clearStatusMessages();
    telemetrySnapshotStreamValue
        .addValue(const TenantAdminTelemetrySettingsSnapshot.empty());
    clearTelemetryForm();
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

  @override
  void onDispose() {
    isRemoteLoadingStreamValue.dispose();
    remoteErrorStreamValue.dispose();
    remoteSuccessStreamValue.dispose();
    firebaseSubmittingStreamValue.dispose();
    pushSubmittingStreamValue.dispose();
    telemetrySubmittingStreamValue.dispose();
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
    _tenantScopeSubscription?.cancel();
  }
}
