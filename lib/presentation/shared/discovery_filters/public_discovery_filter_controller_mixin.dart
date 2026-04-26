import 'dart:async';

import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/domain/app_data/discovery_filter_selection_snapshot.dart';
import 'package:belluga_now/domain/app_data/value_object/app_data_discovery_filter_token_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/discovery_filters_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/discovery_filters_repository_contract_values.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_value/core/stream_value.dart';

mixin PublicDiscoveryFilterControllerMixin {
  DiscoveryFiltersRepositoryContract? get publicDiscoveryFiltersRepository;
  AppDataRepositoryContract? get publicDiscoveryFilterAppDataRepository;
  String get publicDiscoveryFilterSurface;
  DiscoveryFilterPolicy get discoveryFilterPolicy;
  StreamValue<DiscoveryFilterCatalog> get discoveryFilterCatalogStreamValue;
  StreamValue<DiscoveryFilterSelection> get discoveryFilterSelectionStreamValue;
  StreamValue<bool> get isDiscoveryFilterPanelVisibleStreamValue;
  StreamValue<bool> get isDiscoveryFilterCatalogLoadingStreamValue;
  bool get isPublicDiscoveryFilterDisposed;
  String get publicDiscoveryFilterLogLabel;

  void onPublicDiscoveryFilterSelectionChanged(
    DiscoveryFilterSelection selection,
  );

  @protected
  void writePublicDiscoveryFilterState(VoidCallback writer) {
    if (isPublicDiscoveryFilterDisposed) {
      return;
    }
    writer();
  }

  void toggleDiscoveryFilterPanel() {
    setDiscoveryFilterPanelVisible(
      !isDiscoveryFilterPanelVisibleStreamValue.value,
    );
  }

  void setDiscoveryFilterPanelVisible(bool visible) {
    if (isDiscoveryFilterPanelVisibleStreamValue.value == visible) {
      return;
    }
    writePublicDiscoveryFilterState(
      () => isDiscoveryFilterPanelVisibleStreamValue.addValue(visible),
    );
  }

  void updateDiscoveryFilterPanelVisibilityFromScroll(
    double pixels, {
    double epsilon = 0.5,
  }) {
    if (pixels <= epsilon || !isDiscoveryFilterPanelVisibleStreamValue.value) {
      return;
    }
    setDiscoveryFilterPanelVisible(false);
  }

  void setDiscoveryFilterSelection(DiscoveryFilterSelection selection) {
    final repaired = repairPublicDiscoveryFilterSelection(selection);
    if (samePublicDiscoveryFilterSelection(
      discoveryFilterSelectionStreamValue.value,
      repaired,
    )) {
      return;
    }
    writePublicDiscoveryFilterState(
      () => discoveryFilterSelectionStreamValue.addValue(repaired),
    );
    unawaited(persistPublicDiscoveryFilterSelection(repaired));
    onPublicDiscoveryFilterSelectionChanged(repaired);
  }

  Future<void> loadPublicDiscoveryFilterCatalog({
    DiscoveryFilterSelection? restoredSelection,
  }) async {
    final repository = publicDiscoveryFiltersRepository;
    if (repository == null) {
      return;
    }

    writePublicDiscoveryFilterState(
      () => isDiscoveryFilterCatalogLoadingStreamValue.addValue(true),
    );
    try {
      final catalog = await repository.fetchCatalog(
        discoveryFiltersRepoText(publicDiscoveryFilterSurface),
      );
      writePublicDiscoveryFilterState(
        () => discoveryFilterCatalogStreamValue.addValue(catalog),
      );

      final selectionToRestore = restoredSelection ??
          await loadPersistedPublicDiscoveryFilterSelection();
      final repaired = repairPublicDiscoveryFilterSelection(
        selectionToRestore ?? discoveryFilterSelectionStreamValue.value,
        catalogOverride: catalog,
      );
      if (!samePublicDiscoveryFilterSelection(
        discoveryFilterSelectionStreamValue.value,
        repaired,
      )) {
        writePublicDiscoveryFilterState(
          () => discoveryFilterSelectionStreamValue.addValue(repaired),
        );
      }
      if (selectionToRestore != null &&
          !samePublicDiscoveryFilterSelection(selectionToRestore, repaired)) {
        unawaited(persistPublicDiscoveryFilterSelection(repaired));
      }
    } catch (error) {
      debugPrint(
        '$publicDiscoveryFilterLogLabel.loadPublicDiscoveryFilterCatalog failed: $error',
      );
      writePublicDiscoveryFilterState(
        () => discoveryFilterCatalogStreamValue.addValue(
          DiscoveryFilterCatalog(surface: publicDiscoveryFilterSurface),
        ),
      );
    } finally {
      writePublicDiscoveryFilterState(
        () => isDiscoveryFilterCatalogLoadingStreamValue.addValue(false),
      );
    }
  }

  Future<DiscoveryFilterSelection?>
      loadPersistedPublicDiscoveryFilterSelection() async {
    final repository = publicDiscoveryFilterAppDataRepository;
    if (repository == null) {
      return null;
    }
    final stored = await repository.getDiscoveryFilterSelection(
      AppDataDiscoveryFilterTokenValue.fromRaw(publicDiscoveryFilterSurface),
    );
    if (stored == null) {
      return null;
    }
    return discoveryFilterSelectionFromSnapshot(stored);
  }

  Future<void> persistPublicDiscoveryFilterSelection(
    DiscoveryFilterSelection selection,
  ) async {
    final repository = publicDiscoveryFilterAppDataRepository;
    if (repository == null) {
      return;
    }
    try {
      await repository.setDiscoveryFilterSelection(
        AppDataDiscoveryFilterTokenValue.fromRaw(publicDiscoveryFilterSurface),
        discoveryFilterSelectionSnapshot(selection),
      );
    } catch (error) {
      debugPrint(
        '$publicDiscoveryFilterLogLabel.persistPublicDiscoveryFilterSelection failed: $error',
      );
    }
  }

  DiscoveryFilterSelection discoveryFilterSelectionFromSnapshot(
    AppDataDiscoveryFilterSelectionSnapshot snapshot,
  ) {
    return DiscoveryFilterSelection(
      primaryKeys: snapshot.primaryKeys
          .map((value) => value.value)
          .where((value) => value.isNotEmpty)
          .toSet(),
      taxonomyTermKeys: <String, Set<String>>{
        for (final taxonomy in snapshot.taxonomySelections)
          if (!taxonomy.isEmpty)
            taxonomy.taxonomyKey.value: taxonomy.termKeys
                .map((value) => value.value)
                .where((value) => value.isNotEmpty)
                .toSet(),
      },
    );
  }

  AppDataDiscoveryFilterSelectionSnapshot discoveryFilterSelectionSnapshot(
    DiscoveryFilterSelection selection,
  ) {
    return AppDataDiscoveryFilterSelectionSnapshot(
      primaryKeys: selection.primaryKeys
          .map(AppDataDiscoveryFilterTokenValue.fromRaw)
          .where((value) => value.value.isNotEmpty)
          .toList(growable: false),
      taxonomySelections: selection.taxonomyTermKeys.entries
          .map(
            (entry) => AppDataDiscoveryFilterTaxonomySelection(
              taxonomyKey: AppDataDiscoveryFilterTokenValue.fromRaw(entry.key),
              termKeys: entry.value
                  .map(AppDataDiscoveryFilterTokenValue.fromRaw)
                  .where((value) => value.value.isNotEmpty)
                  .toList(growable: false),
            ),
          )
          .where((selection) => !selection.isEmpty)
          .toList(growable: false),
    );
  }

  DiscoveryFilterSelection repairPublicDiscoveryFilterSelection(
    DiscoveryFilterSelection selection, {
    DiscoveryFilterCatalog? catalogOverride,
  }) {
    final catalog = catalogOverride ?? discoveryFilterCatalogStreamValue.value;
    return const DiscoveryFilterSelectionRepair()
        .repair(
          selection: selection,
          catalog: catalog.filters,
          catalogEnvelope: catalog,
          policy: discoveryFilterPolicy,
        )
        .selection;
  }

  bool samePublicDiscoveryFilterSelection(
    DiscoveryFilterSelection left,
    DiscoveryFilterSelection right,
  ) {
    return _sameStringSet(left.primaryKeys, right.primaryKeys) &&
        _sameTaxonomySelection(left.taxonomyTermKeys, right.taxonomyTermKeys);
  }

  bool _sameTaxonomySelection(
    Map<String, Set<String>> left,
    Map<String, Set<String>> right,
  ) {
    if (!setEquals(left.keys.toSet(), right.keys.toSet())) {
      return false;
    }
    for (final key in left.keys) {
      if (!_sameStringSet(left[key] ?? const {}, right[key] ?? const {})) {
        return false;
      }
    }
    return true;
  }

  bool _sameStringSet(Set<String> left, Set<String> right) {
    return setEquals(left, right);
  }
}
