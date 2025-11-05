import 'package:belluga_now/presentation/tenant/screens/mercado/mock_data/mock_mercado_data.dart';
import 'package:belluga_now/presentation/tenant/screens/mercado/models/mercado_producer.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart' show Disposable;
import 'package:stream_value/core/stream_value.dart';

class MercadoController implements Disposable {
  MercadoController()
      : categoriesStreamValue =
            StreamValue<List<MercadoCategory>>(defaultValue: const []),
        selectedCategoriesStreamValue =
            StreamValue<Set<String>>(defaultValue: <String>{}),
        searchTermStreamValue = StreamValue<String?>(defaultValue: null),
        filteredProducersStreamValue =
            StreamValue<List<MercadoProducer>>(defaultValue: const []) {
    _searchListener = () {
      final rawText = searchTextController.text;
      final normalized = rawText.trim().toLowerCase();
      if (normalized.isEmpty) {
        _setSearchTerm(null);
        return;
      }
      if (_searchTermNormalized == normalized) {
        if (searchTermStreamValue.value != rawText) {
          searchTermStreamValue.addValue(rawText);
        }
        return;
      }
      _setSearchTerm(normalized, displayValue: rawText);
    };
    searchTextController.addListener(_searchListener);
  }

  final TextEditingController searchTextController = TextEditingController();
  late final VoidCallback _searchListener;

  final StreamValue<List<MercadoCategory>> categoriesStreamValue;
  final StreamValue<Set<String>> selectedCategoriesStreamValue;
  final StreamValue<String?> searchTermStreamValue;
  final StreamValue<List<MercadoProducer>> filteredProducersStreamValue;

  final List<MercadoProducer> _allProducers = mockMercadoProducers;
  final Map<String, MercadoCategory> _categoriesById = {
    for (final category in mockMercadoCategories) category.id: category,
  };
  String? _searchTermNormalized;

  Future<void> init() async {
    categoriesStreamValue.addValue(mockMercadoCategories);
    filteredProducersStreamValue.addValue(_allProducers);
  }

  void toggleCategory(String categoryId) {
    final current = Set<String>.from(selectedCategoriesStreamValue.value);
    if (current.contains(categoryId)) {
      current.remove(categoryId);
    } else {
      current.add(categoryId);
    }
    selectedCategoriesStreamValue.addValue(
      Set<String>.unmodifiable(current),
    );
    _applyFilters();
  }

  MercadoCategory? categoryById(String categoryId) =>
      _categoriesById[categoryId];

  void clearSearch() {
    if (_searchTermNormalized == null && searchTextController.text.isEmpty) {
      return;
    }
    if (searchTextController.text.isNotEmpty) {
      searchTextController
        ..removeListener(_searchListener)
        ..clear()
        ..addListener(_searchListener);
    }
    _setSearchTerm(null);
  }

  void clearFilters({bool resetSearchText = true}) {
    selectedCategoriesStreamValue.addValue(
      Set<String>.unmodifiable(<String>{}),
    );
    if (resetSearchText) {
      clearSearch();
      return;
    }
    _setSearchTerm(null);
  }

  void _setSearchTerm(String? normalized, {String? displayValue}) {
    _searchTermNormalized = normalized;
    if (normalized == null) {
      searchTermStreamValue.addValue(null);
    } else {
      searchTermStreamValue.addValue(
        displayValue ?? searchTextController.text,
      );
    }
    _applyFilters();
  }

  void _applyFilters() {
    final selectedCategories = selectedCategoriesStreamValue.value;
    final searchTerm = _searchTermNormalized;

    final filtered = _allProducers.where((producer) {
      final matchesCategory = selectedCategories.isEmpty ||
          producer.categories.any(selectedCategories.contains);

      final matchesSearch = searchTerm == null
          ? true
          : producer.name.toLowerCase().contains(searchTerm) ||
              producer.tagline.toLowerCase().contains(searchTerm) ||
              producer.categories.any(
                (category) =>
                    _categoriesById[category]
                        ?.label
                        .toLowerCase()
                        .contains(searchTerm) ??
                    false,
              );

      return matchesCategory && matchesSearch;
    }).toList(growable: false);

    filteredProducersStreamValue.addValue(filtered);
  }

  @override
  void onDispose() {
    categoriesStreamValue.dispose();
    selectedCategoriesStreamValue.dispose();
    searchTermStreamValue.dispose();
    filteredProducersStreamValue.dispose();
    searchTextController
      ..removeListener(_searchListener)
      ..dispose();
  }
}
