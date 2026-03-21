import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';

abstract class AccountProfilesBackendContract {
  Future<List<AccountProfileModel>> fetchAccountProfiles();

  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  });

  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  });

  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug);
}
