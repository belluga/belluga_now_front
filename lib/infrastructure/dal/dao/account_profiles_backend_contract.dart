import 'package:belluga_now/domain/partners/account_profile_model.dart';

abstract class AccountProfilesBackendContract {
  Future<List<AccountProfileModel>> fetchAccountProfiles();

  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  });

  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug);
}
