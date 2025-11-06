import 'package:belluga_now/domain/experiences/experience_model.dart';
import 'package:belluga_now/domain/repositories/experiences_repository_contract.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ExperiencesController implements Disposable {
  ExperiencesController({
    ExperiencesRepositoryContract? repository,
  }) : _repository = repository ?? GetIt.I.get<ExperiencesRepositoryContract>() {
    _searchListener = () {
      final rawText = searchTextController.text;
      if (rawText.trim().isEmpty) {
        if (_searchQuery.isEmpty && searchTermStreamValue.value == null) {
          return;
        }
        _searchQuery = '';
        searchTermStreamValue.addValue(null);
        _applyFilters();
        return;
      }
      updateSearchQuery(rawText);
    };
    searchTextController.addListener(_searchListener);
  }

  final ExperiencesRepositoryContract _repository;

  final TextEditingController searchTextController = TextEditingController();
  late final VoidCallback _searchListener;

  final StreamValue<List<ExperienceModel>> experiencesStreamValue =
      StreamValue<List<ExperienceModel>>(defaultValue: const []);

  final StreamValue<String?> selectedCategoryStreamValue =
      StreamValue<String?>();
  final StreamValue<Set<String>> selectedTagsStreamValue =
      StreamValue<Set<String>>(defaultValue: const <String>{});
  final StreamValue<String?> searchTermStreamValue =
      StreamValue<String?>(defaultValue: null);

  List<ExperienceModel> _allExperiences = const [];
  String? _currentCategory;
  String _searchQuery = '';
  Set<String> _selectedTags = <String>{};

  Set<String> get categories =>
      _allExperiences.map((exp) => exp.category).toSet();
  Set<String> get tags => _allExperiences.expand((exp) => exp.tags).toSet();

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
    final normalized = query.trim().toLowerCase();
    if (_searchQuery == normalized) {
      return;
    }
    _searchQuery = normalized;
    searchTermStreamValue.addValue(
      searchTextController.text.isEmpty ? null : searchTextController.text,
    );
    _applyFilters();
  }

  void clearFilters({bool resetSearchText = true}) {
    _currentCategory = null;
    _searchQuery = '';
    _selectedTags = <String>{};
    selectedCategoryStreamValue.addValue(null);
    selectedTagsStreamValue.addValue(const <String>{});
    if (resetSearchText && searchTextController.text.isNotEmpty) {
      searchTextController
        ..removeListener(_searchListener)
        ..clear()
        ..addListener(_searchListener);
    }
    searchTermStreamValue.addValue(null);
    _applyFilters();
  }

  void toggleTag(String tag) {
    final normalizedTag = tag.trim();
    if (normalizedTag.isEmpty) {
      return;
    }

    final nextTags = _selectedTags.contains(normalizedTag)
        ? (_selectedTags.toSet()..remove(normalizedTag))
        : (_selectedTags.toSet()..add(normalizedTag));

    _selectedTags = nextTags;
    selectedTagsStreamValue.addValue(_selectedTags);
    _applyFilters();
  }

  void clearTagFilters() {
    if (_selectedTags.isEmpty) {
      return;
    }
    _selectedTags = <String>{};
    selectedTagsStreamValue.addValue(_selectedTags);
    _applyFilters();
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

    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((experience) {
        if (experience.tags.isEmpty) {
          return false;
        }
        final normalizedTags =
            experience.tags.map((tag) => tag.toLowerCase()).toSet();
        return _selectedTags
            .map((tag) => tag.toLowerCase())
            .every(normalizedTags.contains);
      });
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
    selectedTagsStreamValue.dispose();
    searchTermStreamValue.dispose();
    searchTextController
      ..removeListener(_searchListener)
      ..dispose();
  }
}
