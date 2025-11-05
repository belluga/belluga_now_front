import 'package:belluga_now/presentation/tenant/screens/mercado/mock_data/mock_mercado_data.dart';
import 'package:belluga_now/presentation/tenant/screens/mercado/models/mercado_producer.dart';
import 'package:get_it/get_it.dart' show Disposable;
import 'package:stream_value/core/stream_value.dart';

class MercadoController implements Disposable {
  MercadoController()
      : categoriesStreamValue =
            StreamValue<List<MercadoCategory>>(defaultValue: const []),
        selectedCategoriesStreamValue =
            StreamValue<Set<String>>(defaultValue: <String>{}),
        searchTermStreamValue = StreamValue<String?>(),
        filteredProducersStreamValue =
            StreamValue<List<MercadoProducer>>(defaultValue: const []);

  final StreamValue<List<MercadoCategory>> categoriesStreamValue;
  final StreamValue<Set<String>> selectedCategoriesStreamValue;
  final StreamValue<String?> searchTermStreamValue;
  final StreamValue<List<MercadoProducer>> filteredProducersStreamValue;

  final List<MercadoProducer> _allProducers = mockMercadoProducers;
  final Map<String, MercadoCategory> _categoriesById = {
    for (final category in mockMercadoCategories) category.id: category,
  };

  Future<void> init() async {
    categoriesStreamValue.addValue(mockMercadoCategories);
    filteredProducersStreamValue.addValue(_allProducers);
  }

  void setSearchTerm(String value) {
    final normalized = value.trim();
    searchTermStreamValue.addValue(
      normalized.isEmpty ? null : normalized.toLowerCase(),
    );
    _applyFilters();
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

  void clearFilters() {
    selectedCategoriesStreamValue.addValue(
      Set<String>.unmodifiable(<String>{}),
    );
    searchTermStreamValue.addValue(null);
    _applyFilters();
  }

  MercadoCategory? categoryById(String categoryId) =>
      _categoriesById[categoryId];

  void _applyFilters() {
    final selectedCategories = selectedCategoriesStreamValue.value;
    final searchTerm = searchTermStreamValue.value;

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
  }
}
