enum TenantAdminAccountProfileCandidateScope {
  queryable,
  contactCapable;

  String get wireValue => switch (this) {
    TenantAdminAccountProfileCandidateScope.queryable => 'queryable',
    TenantAdminAccountProfileCandidateScope.contactCapable => 'contact_capable',
  };
}
