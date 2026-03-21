import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'mock_account_profiles_database.dart';

class MockAccountProfilesBackend implements AccountProfilesBackendContract {
  MockAccountProfilesBackend({MockAccountProfilesDatabase? database})
      : _database = database ?? MockAccountProfilesDatabase();

  final MockAccountProfilesDatabase _database;

  @override
  Future<List<AccountProfileModel>> fetchAccountProfiles() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _database.allAccountProfiles;
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final filtered =
        _database.searchAccountProfiles(query: query, typeFilter: typeFilter);
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= filtered.length || startIndex < 0) {
      return const PagedAccountProfilesResult(
        profiles: <AccountProfileModel>[],
        hasMore: false,
      );
    }

    final endIndex = (startIndex + pageSize).clamp(0, filtered.length);
    final pageItems = filtered.sublist(startIndex, endIndex);
    return PagedAccountProfilesResult(
      profiles: pageItems,
      hasMore: endIndex < filtered.length,
    );
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _database.searchAccountProfiles(
        query: query, typeFilter: typeFilter);
  }

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _database.getAccountProfileBySlug(slug);
  }
}
