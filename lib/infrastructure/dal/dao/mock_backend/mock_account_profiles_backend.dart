import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/datasources/mock_account_profiles_database.dart';

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
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _database.searchAccountProfiles(query: query, typeFilter: typeFilter);
  }

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _database.getAccountProfileBySlug(slug);
  }
}
