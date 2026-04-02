enum TenantAdminEventAccountProfileCandidateType {
  artist,
  physicalHost;

  String get apiValue => switch (this) {
        TenantAdminEventAccountProfileCandidateType.artist => 'artist',
        TenantAdminEventAccountProfileCandidateType.physicalHost =>
          'physical_host',
      };
}
