import 'package:belluga_now/domain/experiences/experience_model.dart';
import 'package:belluga_now/domain/repositories/experiences_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ExperiencesController implements Disposable {
  ExperiencesController({
    ExperiencesRepositoryContract? repository,
  }) : _repository =
            repository ?? GetIt.I.get<ExperiencesRepositoryContract>();

  final ExperiencesRepositoryContract _repository;

  final StreamValue<List<ExperienceModel>> experiencesStreamValue =
      StreamValue<List<ExperienceModel>>(defaultValue: const []);

  final StreamValue<String?> selectedCategoryStreamValue =
      StreamValue<String?>();

  List<ExperienceModel> _allExperiences = const [];
  String? _currentCategory;
  String _searchQuery = '';

  Set<String> get categories =>
      _allExperiences.map((exp) => exp.category).toSet();

  Future<void> init() async {
    final experiences = await _repository.fetchExperiences();
    _allExperiences = experiences;
    experiencesStreamValue.addValue(experiences);
  }

  void selectCategory(String? category) {
    _currentCategory = category?.isEmpty == true ? null : category;
    selectedCategoryStreamValue.addValue(_currentCategory);
    _applyFilters();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
  }

  void clearFilters() {
    _currentCategory = null;
    _searchQuery = '';
    selectedCategoryStreamValue.addValue(null);
    experiencesStreamValue.addValue(_allExperiences);
  }

  void _applyFilters() {
    Iterable<ExperienceModel> filtered = _allExperiences;

    if (_currentCategory != null && _currentCategory!.isNotEmpty) {
      filtered = filtered.where(
        (experience) =>
            experience.category.toLowerCase() ==
            _currentCategory!.toLowerCase(),
      );
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((experience) {
        final title = experience.title.toLowerCase();
        final provider = experience.providerName.toLowerCase();
        final category = experience.category.toLowerCase();
        return title.contains(_searchQuery) ||
            provider.contains(_searchQuery) ||
            category.contains(_searchQuery);
      });
    }

    experiencesStreamValue.addValue(filtered.toList(growable: false));
  }

  @override
  void onDispose() {
    experiencesStreamValue.dispose();
    selectedCategoryStreamValue.dispose();
  }
}
