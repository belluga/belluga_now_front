class AccountProfileCandidateGenericEndpointCase {
  Future<void> loadLegacyCandidatePage() async {
    // expect_lint: account_profile_candidate_generic_endpoint_forbidden
    await fetchAccountProfilesPage(page: 1, queryableOnly: true);
  }

  Future<void> loadRenamedCandidatePage() async {
    // expect_lint: account_profile_candidate_generic_endpoint_forbidden
    await fetchAccountProfilesPage(page: 1);
  }

  Future<void> loadCanonicalCandidatePage() async {
    // expect_no_lint: account_profile_candidate_generic_endpoint_forbidden
    await fetchAccountProfileCandidatesPage(scope: 'queryable', page: 1);
  }

  // expect_lint: account_profile_candidate_generic_endpoint_forbidden
  Future<void> loadContactSourceCandidates() async {}

  // expect_lint: account_profile_candidate_generic_endpoint_forbidden
  Future<void> fetchAccountProfilesPage({
    required int page,
    bool queryableOnly = false,
  }) async {}

  Future<void> fetchAccountProfileCandidatesPage({
    required String scope,
    required int page,
  }) async {}
}
