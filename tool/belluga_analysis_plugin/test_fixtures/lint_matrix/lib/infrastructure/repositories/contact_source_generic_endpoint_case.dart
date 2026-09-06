class ContactSourceController {
  Future<void> loadMirroredProfiles() async {
    // expect_lint: account_profile_candidate_generic_endpoint_forbidden
    await fetchAccountProfilesPage(page: 1);
  }

  Future<void> fetchAccountProfilesPage({required int page}) async {}
}
