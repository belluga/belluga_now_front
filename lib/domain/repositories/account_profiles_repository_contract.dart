import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AccountProfilesRepositoryContract {
  /// Stream of all account profiles
  final allAccountProfilesStreamValue =
      StreamValue<List<AccountProfileModel>>(defaultValue: const []);

  /// Stream of favorite account profile IDs
  final favoriteAccountProfileIdsStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});

  /// Initialize repository and load data
  Future<void> init();

  /// Fetch all account profiles
  Future<List<AccountProfileModel>> fetchAllAccountProfiles();

  /// Fetch paged account profiles for scrolling surfaces.
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
  });

  /// Search account profiles by query and optional type filter
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
  });

  /// Get account profile by slug
  Future<AccountProfileModel?> getAccountProfileBySlug(String slug);

  /// Toggle favorite status for an account profile
  Future<void> toggleFavorite(String accountProfileId);

  /// Check if account profile is favorited
  bool isFavorite(String accountProfileId);

  /// Get all favorite account profiles
  List<AccountProfileModel> getFavoriteAccountProfiles();
}
