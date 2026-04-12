enum TenantAdminEventAccountProfileCandidateType {
  relatedAccountProfile,
  physicalHost;

  String get apiValue => switch (this) {
        TenantAdminEventAccountProfileCandidateType.relatedAccountProfile =>
          'related_account_profile',
        TenantAdminEventAccountProfileCandidateType.physicalHost =>
          'physical_host',
      };
}
