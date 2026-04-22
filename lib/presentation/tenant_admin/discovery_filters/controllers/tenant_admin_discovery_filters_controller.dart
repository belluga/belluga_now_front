import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_settings_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_discovery_filters_settings_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_map_filter_rule_values.dart';
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
    TenantAdminAccountProfilesRepositoryContract? accountProfilesRepository,
    TenantAdminStaticAssetsRepositoryContract? staticAssetsRepository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminEventsRepositoryContract? eventsRepository,
  })  : _settingsRepository = settingsRepository ??
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
        _eventsRepository = eventsRepository ??
            (GetIt.I.isRegistered<TenantAdminEventsRepositoryContract>()
                ? GetIt.I.get<TenantAdminEventsRepositoryContract>()
                : null);

  final TenantAdminSettingsRepositoryContract _settingsRepository;
  final TenantAdminAccountProfilesRepositoryContract?
      _accountProfilesRepository;
  final TenantAdminStaticAssetsRepositoryContract? _staticAssetsRepository;
  final TenantAdminTaxonomiesRepositoryContract? _taxonomiesRepository;
  final TenantAdminEventsRepositoryContract? _eventsRepository;

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
      final accountRepo = _accountProfilesRepository;
      final staticRepo = _staticAssetsRepository;
      final taxonomyRepo = _taxonomiesRepository;
      final eventsRepo = _eventsRepository;
      if (accountRepo == null ||
          staticRepo == null ||
          taxonomyRepo == null ||
          eventsRepo == null) {
        _emitRuleCatalog(
          const TenantAdminMapFilterRuleCatalog.empty(),
        );
        return;
      }

      final eventTypesFuture = eventsRepo.fetchEventTypes();
      await Future.wait<void>([
        accountRepo.loadAllProfileTypes(),
        staticRepo.loadAllStaticProfileTypes(),
        taxonomyRepo.loadAllTaxonomies(),
      ]);

      final accountTypes = accountRepo.profileTypesStreamValue.value ??
          const <TenantAdminProfileTypeDefinition>[];
      final staticTypes = staticRepo.staticProfileTypesStreamValue.value ??
          const <TenantAdminStaticProfileTypeDefinition>[];
      final eventTypes = await eventTypesFuture;
      final taxonomies = taxonomyRepo.taxonomiesStreamValue.value ??
          const <TenantAdminTaxonomyDefinition>[];
      final termsByTaxonomySlug =
          await _loadTermsByTaxonomySlug(taxonomies: taxonomies);

      _emitRuleCatalog(
        _buildRuleCatalog(
          accountTypes: accountTypes,
          staticTypes: staticTypes,
          eventTypes: eventTypes,
          taxonomies: taxonomies,
          termsByTaxonomySlug: termsByTaxonomySlug,
        ),
      );
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
        taxonomyId: TenantAdminTaxRepoString.fromRaw(
          taxonomy.id,
          defaultValue: '',
          isRequired: true,
        ),
      );
      entries.add(
        MapEntry<String, List<TenantAdminTaxonomyTermDefinition>>(
          taxonomy.slug,
          taxonomyRepo.termsStreamValue.value ??
              const <TenantAdminTaxonomyTermDefinition>[],
        ),
      );
    }
    return {for (final entry in entries) entry.key: entry.value};
  }

  TenantAdminMapFilterRuleCatalog _buildRuleCatalog({
    required List<TenantAdminProfileTypeDefinition> accountTypes,
    required List<TenantAdminStaticProfileTypeDefinition> staticTypes,
    required List<TenantAdminEventType> eventTypes,
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

    final eventTypeOptions = eventTypes
        .where((item) => item.slug.trim().isNotEmpty)
        .map(
          (item) => TenantAdminMapFilterTypeOption(
            slugValue: _tokenValue(item.slug.trim().toLowerCase()),
            labelValue: _requiredTextValue(
              item.name.trim().isEmpty ? item.slug : item.name.trim(),
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
      for (final term in termsByTaxonomySlug[taxonomy.slug] ??
          const <TenantAdminTaxonomyTermDefinition>[]) {
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
            List<TenantAdminMapFilterTypeOption>.unmodifiable(
          eventTypeOptions,
        ),
      }),
      taxonomyTermsBySource: TenantAdminMapFilterTaxonomyOptionsBySourceValue({
        for (final entry in taxonomyBySource.entries)
          entry.key: List<TenantAdminMapFilterTaxonomyTermOption>.unmodifiable(
            entry.value,
          ),
      }),
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
