class AccountProfileAdministrativeListingCase {
  Future<void> loadAdministrativePage() async {
    // expect_no_lint: account_profile_candidate_generic_endpoint_forbidden
    await fetchAccountProfilesPage(page: 1);
  }

  Future<void> fetchAccountProfilesPage({required int page}) async {}
}
