enum TenantAdminEventTemporalBucket {
  past,
  now,
  future;

  String get apiValue => switch (this) {
        TenantAdminEventTemporalBucket.past => 'past',
        TenantAdminEventTemporalBucket.now => 'now',
        TenantAdminEventTemporalBucket.future => 'future',
      };

  String get label => switch (this) {
        TenantAdminEventTemporalBucket.past => 'Passados',
        TenantAdminEventTemporalBucket.now => 'Acontecendo agora',
        TenantAdminEventTemporalBucket.future => 'Futuros',
      };

  static const Set<TenantAdminEventTemporalBucket> defaultSelection =
      <TenantAdminEventTemporalBucket>{
    TenantAdminEventTemporalBucket.now,
    TenantAdminEventTemporalBucket.future,
  };
}
