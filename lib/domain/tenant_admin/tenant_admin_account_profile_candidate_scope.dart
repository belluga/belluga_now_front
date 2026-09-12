enum TenantAdminAccountProfileCandidateScope {
  queryable,
  contactCapable,
  homeFavoritesPinnedProfile;

  String get wireValue => switch (this) {
    TenantAdminAccountProfileCandidateScope.queryable => 'queryable',
    TenantAdminAccountProfileCandidateScope.contactCapable => 'contact_capable',
    TenantAdminAccountProfileCandidateScope.homeFavoritesPinnedProfile =>
      'home_favorites_pinned_profile',
  };
}
