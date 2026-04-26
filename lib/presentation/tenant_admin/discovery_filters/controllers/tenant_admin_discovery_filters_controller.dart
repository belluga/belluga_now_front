import 'package:belluga_now/domain/repositories/tenant_admin_discovery_filter_rule_catalog_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_discovery_filters_settings_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_item.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_items.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_query.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filters_settings.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminDiscoveryFiltersController implements Disposable {
  TenantAdminDiscoveryFiltersController({
    TenantAdminSettingsRepositoryContract? settingsRepository,
    TenantAdminDiscoveryFilterRuleCatalogRepositoryContract?
        ruleCatalogRepository,
  })  : _settingsRepository = settingsRepository ??
            GetIt.I.get<TenantAdminSettingsRepositoryContract>(),
        _ruleCatalogRepository = ruleCatalogRepository ??
            GetIt.I
                .get<TenantAdminDiscoveryFilterRuleCatalogRepositoryContract>();

  final TenantAdminSettingsRepositoryContract _settingsRepository;
  final TenantAdminDiscoveryFilterRuleCatalogRepositoryContract
      _ruleCatalogRepository;

  bool _isDisposed = false;
  TenantAdminDiscoveryFiltersSettings _settings =
      TenantAdminDiscoveryFiltersSettings.empty();

  final StreamValue<TenantAdminDiscoveryFiltersSettings> settingsStreamValue =
      StreamValue<TenantAdminDiscoveryFiltersSettings>(
    defaultValue: TenantAdminDiscoveryFiltersSettings.empty(),
  );
  final StreamValue<bool> isLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> isSubmittingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String> remoteErrorStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<String> remoteSuccessStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<TenantAdminMapFilterRuleCatalog> ruleCatalogStreamValue =
      StreamValue<TenantAdminMapFilterRuleCatalog>(
    defaultValue: const TenantAdminMapFilterRuleCatalog.empty(),
  );
  final StreamValue<bool> ruleCatalogLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);

  Future<void> init() {
    if (_settings.rawDiscoveryFilters.value.isNotEmpty) {
      return Future<void>.value();
    }
    return loadSettings();
  }

  Future<void> loadSettings() async {
    if (_isDisposed) {
      return;
    }
    _emitIsLoading(true);
    try {
      final settingsValue =
          await _settingsRepository.fetchDiscoveryFiltersSettings();
      _applySettings(
        TenantAdminDiscoveryFiltersSettings(
          rawDiscoveryFiltersValue: settingsValue.rawDiscoveryFilters,
        ),
      );
    } catch (error) {
      _emitRemoteError(error.toString());
    } finally {
      _emitIsLoading(false);
    }
  }

  Future<void> saveFilters(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
  ) async {
    if (_isDisposed) {
      return;
    }
    _emitIsSubmitting(true);
    try {
      final updated = await _settingsRepository.updateDiscoveryFiltersSettings(
        settings: TenantAdminDiscoveryFiltersSettingsValue(
          _settings.rawDiscoveryFilters,
        ),
      );
      _applySettings(
        TenantAdminDiscoveryFiltersSettings(
          rawDiscoveryFiltersValue: updated.rawDiscoveryFilters,
        ),
      );
      _emitRemoteSuccess(
        'Filtros de ${surface.title} atualizados com sucesso.',
      );
    } catch (error) {
      _emitRemoteError(error.toString());
    } finally {
      _emitIsSubmitting(false);
    }
  }

  TenantAdminDiscoveryFilterCatalogItems filtersForSurface(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
  ) {
    return _settings.filtersForSurface(surface.key);
  }

  void addFilterItem(TenantAdminDiscoveryFilterSurfaceDefinition surface) {
    final current = filtersForSurface(surface).toList();
    final nextIndex = current.length + 1;
    current.add(
      TenantAdminDiscoveryFilterCatalogItem(
        keyValue: _tokenValue(_buildDefaultKey(nextIndex, current)),
        labelValue: _requiredTextValue('Filtro ${nextIndex.toString()}'),
        query: TenantAdminDiscoveryFilterQuery(
          entityValues: surface.allowedSources.map(
            (source) => _tokenValue(source.apiValue),
          ),
        ),
      ),
    );
    _replaceFilters(surface, current);
  }

  void removeFilterItem(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
    int index,
  ) {
    final current = filtersForSurface(surface).toList();
    if (index < 0 || index >= current.length) {
      return;
    }
    current.removeAt(index);
    _replaceFilters(surface, current);
  }

  void moveFilterItemUp(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
    int index,
  ) {
    final current = filtersForSurface(surface).toList();
    if (index <= 0 || index >= current.length) {
      return;
    }
    final item = current.removeAt(index);
    current.insert(index - 1, item);
    _replaceFilters(surface, current);
  }

  void moveFilterItemDown(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
    int index,
  ) {
    final current = filtersForSurface(surface).toList();
    if (index < 0 || index >= current.length - 1) {
      return;
    }
    final item = current.removeAt(index);
    current.insert(index + 1, item);
    _replaceFilters(surface, current);
  }

  void updateFilterKey(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
    int index,
    String rawKey,
  ) {
    final current = filtersForSurface(surface).toList();
    if (index < 0 || index >= current.length) {
      return;
    }
    final key = _normalizeToken(rawKey);
    if (key.isEmpty) {
      _emitRemoteError(
        'A chave do filtro deve conter letras, números, hífen ou underscore.',
      );
      return;
    }
    current[index] = current[index].copyWith(keyValue: _tokenValue(key));
    _replaceFilters(surface, current);
    _emitRemoteError('');
  }

  void updateFilterLabel(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
    int index,
    String rawLabel,
  ) {
    final current = filtersForSurface(surface).toList();
    if (index < 0 || index >= current.length) {
      return;
    }
    final label = rawLabel.trim();
    if (label.isEmpty) {
      _emitRemoteError('O rótulo do filtro é obrigatório.');
      return;
    }
    current[index] = current[index].copyWith(
      labelValue: _requiredTextValue(label),
    );
    _replaceFilters(surface, current);
    _emitRemoteError('');
  }

  void updateFilterRule(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
    int index,
    TenantAdminDiscoveryFilterCatalogItem nextItem,
  ) {
    final current = filtersForSurface(surface).toList();
    if (index < 0 || index >= current.length) {
      return;
    }
    final allowedEntities =
        surface.allowedSources.map((source) => source.apiValue).toSet();
    final entities = nextItem.query.entities
        .where((entity) => allowedEntities.contains(entity))
        .map(_tokenValue)
        .toList(growable: false);
    if (entities.isEmpty) {
      _emitRemoteError(
        'Selecione pelo menos uma entidade válida para esta superfície.',
      );
      return;
    }
    final entityKeys = entities.map((entry) => entry.value).toSet();
    final typesByEntity = <String, List<TenantAdminLowercaseTokenValue>>{};
    for (final entry in nextItem.query.typeValuesByEntity.entries) {
      if (!entityKeys.contains(entry.key)) {
        continue;
      }
      typesByEntity[entry.key] =
          entry.value.map((token) => _tokenValue(token.value)).toList();
    }
    final taxonomyByGroup = <String, List<TenantAdminLowercaseTokenValue>>{};
    for (final entry in nextItem.query.taxonomyValuesByGroup.entries) {
      taxonomyByGroup[entry.key] =
          entry.value.map((token) => _tokenValue(token.value)).toList();
    }

    current[index] = current[index].copyWith(
      query: TenantAdminDiscoveryFilterQuery(
        entityValues: entities,
        typeValuesByEntity: typesByEntity,
        taxonomyValuesByGroup: taxonomyByGroup,
      ),
    );
    _replaceFilters(surface, current);
    _emitRemoteError('');
  }

  void updateFilterVisual(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
    int index,
    TenantAdminDiscoveryFilterCatalogItem nextItem,
  ) {
    final current = filtersForSurface(surface).toList();
    if (index < 0 || index >= current.length) {
      return;
    }
    final imageUri = _sanitizeImageUri(nextItem.imageUri);
    if (nextItem.imageUri?.trim().isNotEmpty == true && imageUri == null) {
      _emitRemoteError(
        'URL de imagem inválida. Use formato http/https.',
      );
      return;
    }
    final markerOverride =
        surface.supportsMarkerOverride ? nextItem.markerOverride : null;
    current[index] = current[index].copyWith(
      imageUriValue: imageUri == null
          ? null
          : (TenantAdminOptionalUrlValue()..parse(imageUri)),
      clearImageUriValue: TenantAdminFlagValue(imageUri == null),
      overrideMarkerValue: TenantAdminFlagValue(
          surface.supportsMarkerOverride && nextItem.overrideMarker),
      markerOverride: markerOverride,
      clearMarkerOverrideValue: TenantAdminFlagValue(
          !surface.supportsMarkerOverride || !nextItem.overrideMarker),
    );
    _replaceFilters(surface, current);
    _emitRemoteError('');
  }

  Future<void> loadRuleCatalog() async {
    if (_isDisposed) {
      return;
    }
    if (ruleCatalogLoadingStreamValue.value) {
      return;
    }
    _emitRuleCatalogLoading(true);
    try {
      _emitRuleCatalog(await _ruleCatalogRepository.fetchRuleCatalog());
    } catch (error) {
      _emitRemoteError(
        'Não foi possível carregar catálogo de regras dos filtros: $error',
      );
    } finally {
      _emitRuleCatalogLoading(false);
    }
  }

  void _applySettings(TenantAdminDiscoveryFiltersSettings settings) {
    if (_isDisposed) {
      return;
    }
    _settings = settings;
    _emitSettings(settings);
  }

  void _emitSettings(TenantAdminDiscoveryFiltersSettings value) {
    if (_isDisposed) {
      return;
    }
    settingsStreamValue.addValue(value);
  }

  void _emitIsLoading(bool value) {
    if (_isDisposed) {
      return;
    }
    isLoadingStreamValue.addValue(value);
  }

  void _emitIsSubmitting(bool value) {
    if (_isDisposed) {
      return;
    }
    isSubmittingStreamValue.addValue(value);
  }

  void _emitRemoteError(String value) {
    if (_isDisposed) {
      return;
    }
    remoteErrorStreamValue.addValue(value);
  }

  void _emitRemoteSuccess(String value) {
    if (_isDisposed) {
      return;
    }
    remoteSuccessStreamValue.addValue(value);
  }

  void _emitRuleCatalog(TenantAdminMapFilterRuleCatalog value) {
    if (_isDisposed) {
      return;
    }
    ruleCatalogStreamValue.addValue(value);
  }

  void _emitRuleCatalogLoading(bool value) {
    if (_isDisposed) {
      return;
    }
    ruleCatalogLoadingStreamValue.addValue(value);
  }

  void _replaceFilters(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
    List<TenantAdminDiscoveryFilterCatalogItem> nextFilters,
  ) {
    _applySettings(
      _settings.applyFilters(
        surface: surface,
        filters: TenantAdminDiscoveryFilterCatalogItems(nextFilters),
      ),
    );
  }

  String _buildDefaultKey(
    int nextIndex,
    List<TenantAdminDiscoveryFilterCatalogItem> current,
  ) {
    var key = 'filter_$nextIndex';
    final used = current.map((item) => item.key).toSet();
    var suffix = nextIndex;
    while (used.contains(key)) {
      suffix += 1;
      key = 'filter_$suffix';
    }
    return key;
  }

  String? _sanitizeImageUri(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.trim().isEmpty) {
      return null;
    }
    return value;
  }

  String _normalizeToken(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(' ', '_');
    return RegExp(r'^[a-z0-9_-]+$').hasMatch(normalized) ? normalized : '';
  }

  TenantAdminLowercaseTokenValue _tokenValue(String raw) =>
      TenantAdminLowercaseTokenValue.fromRaw(raw);

  TenantAdminRequiredTextValue _requiredTextValue(String raw) =>
      TenantAdminRequiredTextValue()..parse(raw);

  @override
  Future<void> onDispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    isLoadingStreamValue.dispose();
    isSubmittingStreamValue.dispose();
    remoteErrorStreamValue.dispose();
    remoteSuccessStreamValue.dispose();
    settingsStreamValue.dispose();
    ruleCatalogStreamValue.dispose();
    ruleCatalogLoadingStreamValue.dispose();
  }
}
