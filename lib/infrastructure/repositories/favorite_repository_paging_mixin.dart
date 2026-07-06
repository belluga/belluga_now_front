import 'package:belluga_now/domain/favorite/paged_favorite_resumes_result.dart';
import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:stream_value/core/stream_value.dart';

mixin FavoriteRepositoryPagingMixin on FavoriteRepositoryContract {
  static const int _favoriteResumesPageSize = 10;
  static const int _favoriteResumesFetchMaxAttempts = 3;
  static const Duration _favoriteResumesRetryDelay = Duration(
    milliseconds: 250,
  );

  final StreamValue<bool> _hasMoreFavoriteResumesStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> _isFavoriteResumesPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);

  bool _isFetchingFavoriteResumesPage = false;
  bool _hasMoreFavoriteResumes = false;
  int _currentFavoriteResumesPage = 0;
  int _favoriteResumesLoadVersion = 0;

  @override
  StreamValue<bool> get hasMoreFavoriteResumesStreamValue =>
      _hasMoreFavoriteResumesStreamValue;

  @override
  StreamValue<bool> get isFavoriteResumesPageLoadingStreamValue =>
      _isFavoriteResumesPageLoadingStreamValue;

  Future<PagedFavoriteResumesResult> fetchFavoriteResumesPage({
    required int page,
    required int pageSize,
  }) async {
    final resolvedPage = page < 1 ? 1 : page;
    final resolvedPageSize = pageSize < 1 ? _favoriteResumesPageSize : pageSize;
    final favorites = await fetchFavoriteResumes();
    final startIndex = (resolvedPage - 1) * resolvedPageSize;
    final items = favorites
        .skip(startIndex)
        .take(resolvedPageSize)
        .toList(growable: false);

    return PagedFavoriteResumesResult(
      items: items,
      hasMore: (startIndex + resolvedPageSize) < favorites.length,
    );
  }

  @override
  Future<void> initializeFavoriteResumes() async {
    if (favoriteResumesStreamValue.value != null) {
      return;
    }

    await refreshFavoriteResumes();
  }

  @override
  Future<void> refreshFavoriteResumes() async {
    final snapshot = _FavoriteResumesPagingSnapshot(
      items: favoriteResumesStreamValue.value,
      currentPage: _currentFavoriteResumesPage,
      hasMore: _hasMoreFavoriteResumes,
    );
    final clearExistingValue = snapshot.items == null;
    final targetPage = snapshot.currentPage > 0 ? snapshot.currentPage : 1;

    for (
      var attempt = 1;
      attempt <= _favoriteResumesFetchMaxAttempts;
      attempt++
    ) {
      try {
        await _reloadFavoriteResumesWindow(
          targetPage: targetPage,
          clearExistingValue: clearExistingValue,
        );
        return;
      } catch (_) {
        final hasMoreAttempts = attempt < _favoriteResumesFetchMaxAttempts;
        if (hasMoreAttempts) {
          await Future<void>.delayed(_favoriteResumesRetryDelay);
        }
      }
    }

    if (snapshot.items != null) {
      _restoreFavoriteResumesPagingSnapshot(snapshot);
      return;
    }

    final recovered = await _recoverInitialFavoriteResumesDirectRead();
    if (recovered) {
      return;
    }

    _resetFavoriteResumesPaginationState();
    favoriteResumesStreamValue.addValue(const <FavoriteResume>[]);
  }

  Future<bool> _recoverInitialFavoriteResumesDirectRead() async {
    try {
      final favorites = await fetchFavoriteResumes();
      final pageItems = favorites
          .take(_favoriteResumesPageSize)
          .toList(growable: false);

      favoriteResumesStreamValue.addValue(pageItems);
      _hasMoreFavoriteResumes = favorites.length > _favoriteResumesPageSize;
      hasMoreFavoriteResumesStreamValue.addValue(_hasMoreFavoriteResumes);
      _currentFavoriteResumesPage = pageItems.isEmpty ? 0 : 1;
      isFavoriteResumesPageLoadingStreamValue.addValue(false);
      _isFetchingFavoriteResumesPage = false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _reloadFavoriteResumesWindow({
    required int targetPage,
    required bool clearExistingValue,
  }) async {
    final loadVersion = _beginFavoriteResumesReload();
    _isFetchingFavoriteResumesPage = true;
    if (targetPage > 1) {
      isFavoriteResumesPageLoadingStreamValue.addValue(true);
    }
    if (clearExistingValue) {
      favoriteResumesStreamValue.addValue(null);
    }

    final mergedItems = <FavoriteResume>[];
    var hasMore = false;
    var lastLoadedPage = 0;

    try {
      for (var page = 1; page <= targetPage; page++) {
        final result = await fetchFavoriteResumesPage(
          page: page,
          pageSize: _favoriteResumesPageSize,
        );

        if (loadVersion != _favoriteResumesLoadVersion) {
          return;
        }

        if (page == 1) {
          mergedItems
            ..clear()
            ..addAll(result.items);
        } else {
          mergedItems.addAll(result.items);
        }

        hasMore = result.hasMore;
        lastLoadedPage = page;

        if (!result.hasMore && page < targetPage) {
          break;
        }
      }

      if (loadVersion != _favoriteResumesLoadVersion) {
        return;
      }

      favoriteResumesStreamValue.addValue(mergedItems);
      _hasMoreFavoriteResumes = hasMore;
      hasMoreFavoriteResumesStreamValue.addValue(hasMore);
      _currentFavoriteResumesPage = lastLoadedPage;
    } finally {
      _finishFavoriteResumesLoad(loadVersion);
    }
  }

  @override
  Future<void> loadNextFavoriteResumesPage() async {
    if (_isFetchingFavoriteResumesPage || !_hasMoreFavoriteResumes) {
      return;
    }

    await _fetchFavoriteResumesPage(
      page: _currentFavoriteResumesPage + 1,
      loadVersion: _favoriteResumesLoadVersion,
    );
  }

  Future<void> _fetchFavoriteResumesPage({
    required int page,
    required int loadVersion,
  }) async {
    if (_isFetchingFavoriteResumesPage) {
      return;
    }

    _isFetchingFavoriteResumesPage = true;
    if (page > 1) {
      isFavoriteResumesPageLoadingStreamValue.addValue(true);
    }

    try {
      final result = await fetchFavoriteResumesPage(
        page: page,
        pageSize: _favoriteResumesPageSize,
      );
      if (loadVersion != _favoriteResumesLoadVersion) {
        return;
      }
      final currentItems = page == 1
          ? const <FavoriteResume>[]
          : (favoriteResumesStreamValue.value ?? const <FavoriteResume>[]);
      final mergedItems = page == 1
          ? result.items
          : <FavoriteResume>[...currentItems, ...result.items];

      favoriteResumesStreamValue.addValue(mergedItems);
      _hasMoreFavoriteResumes = result.hasMore;
      hasMoreFavoriteResumesStreamValue.addValue(result.hasMore);
      _currentFavoriteResumesPage = page;
    } finally {
      _finishFavoriteResumesLoad(loadVersion);
    }
  }

  int _beginFavoriteResumesReload() {
    _favoriteResumesLoadVersion += 1;
    _resetFavoriteResumesPaginationState();

    return _favoriteResumesLoadVersion;
  }

  void _finishFavoriteResumesLoad(int loadVersion) {
    if (loadVersion != _favoriteResumesLoadVersion) {
      return;
    }

    _isFetchingFavoriteResumesPage = false;
    isFavoriteResumesPageLoadingStreamValue.addValue(false);
  }

  void _restoreFavoriteResumesPagingSnapshot(
    _FavoriteResumesPagingSnapshot snapshot,
  ) {
    favoriteResumesStreamValue.addValue(snapshot.items);
    _hasMoreFavoriteResumes = snapshot.hasMore;
    _currentFavoriteResumesPage = snapshot.currentPage;
    hasMoreFavoriteResumesStreamValue.addValue(snapshot.hasMore);
    isFavoriteResumesPageLoadingStreamValue.addValue(false);
    _isFetchingFavoriteResumesPage = false;
  }

  void _resetFavoriteResumesPaginationState() {
    _isFetchingFavoriteResumesPage = false;
    _hasMoreFavoriteResumes = false;
    _currentFavoriteResumesPage = 0;
    hasMoreFavoriteResumesStreamValue.addValue(false);
    isFavoriteResumesPageLoadingStreamValue.addValue(false);
  }
}

class _FavoriteResumesPagingSnapshot {
  const _FavoriteResumesPagingSnapshot({
    required this.items,
    required this.currentPage,
    required this.hasMore,
  });

  final List<FavoriteResume>? items;
  final int currentPage;
  final bool hasMore;
}
