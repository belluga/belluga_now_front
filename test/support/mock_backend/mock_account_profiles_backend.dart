import 'package:belluga_now/domain/partners/account_profile_complete.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group_member_page.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'mock_account_profiles_database.dart';

class MockAccountProfilesBackend implements AccountProfilesBackendContract {
  MockAccountProfilesBackend({MockAccountProfilesDatabase? database})
    : _database = database ?? MockAccountProfilesDatabase();

  final MockAccountProfilesDatabase _database;

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
    List<String>? typeFilters,
    List<dynamic>? taxonomyFilters,
    List<String>? allowedTypes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final filtered = _database.searchAccountProfiles(
      query: query,
      typeFilter: typeFilter,
    );
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= filtered.length || startIndex < 0) {
      return pagedAccountProfilesResultFromRaw(
        profiles: <AccountProfileComplete>[],
        hasMore: false,
      );
    }

    final endIndex = (startIndex + pageSize).clamp(0, filtered.length);
    final pageItems = filtered.sublist(startIndex, endIndex);
    return pagedAccountProfilesResultFromRaw(
      profiles: pageItems,
      hasMore: endIndex < filtered.length,
    );
  }

  @override
  Future<AccountProfileComplete?> fetchAccountProfileBySlug(String slug) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _database.getAccountProfileBySlug(slug);
  }

  @override
  Future<AccountProfileSummaryPage> fetchNestedGroupMembersPageByPath(
    String membersPath, {
    String? cursor,
    String? search,
  }) async {
    final normalizedCursor = cursor?.trim();
    final normalizedSearch = search?.trim();
    if ((normalizedCursor != null && normalizedCursor.isNotEmpty) ||
        (normalizedSearch != null && normalizedSearch.isNotEmpty)) {
      return const AccountProfileSummaryPage.empty();
    }

    await Future.delayed(const Duration(milliseconds: 50));
    return const AccountProfileSummaryPage.empty();
  }

  @override
  Future<List<AccountProfileComplete>> fetchNearbyAccountProfiles({
    int pageSize = 10,
    List<String>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final all = _database.allAccountProfiles;
    if (all.isEmpty) {
      return const <AccountProfileComplete>[];
    }
    return all.take(pageSize).toList(growable: false);
  }
}
