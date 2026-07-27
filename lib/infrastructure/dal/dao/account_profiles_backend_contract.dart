import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group_member.dart';
import 'package:belluga_now/domain/partners/account_profile_nested_group_member_page.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_taxonomy_filter.dart';

abstract class AccountProfilesBackendContract {
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
    List<String>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
    List<String>? allowedTypes,
  });

  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug);

  Future<List<AccountProfileNestedGroupMember>> fetchNestedGroupMembersByPath(
    String membersPath,
  );

  Future<AccountProfileNestedGroupMemberPage> fetchNestedGroupMembersPageByPath(
    String membersPath, {
    String? cursor,
  }) async {
    final normalizedCursor = cursor?.trim();
    if (normalizedCursor != null && normalizedCursor.isNotEmpty) {
      return const AccountProfileNestedGroupMemberPage.empty();
    }

    final items = await fetchNestedGroupMembersByPath(membersPath);
    return AccountProfileNestedGroupMemberPage(
      items: items,
      nextCursorValue: null,
    );
  }

  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
    List<String>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  });
}
