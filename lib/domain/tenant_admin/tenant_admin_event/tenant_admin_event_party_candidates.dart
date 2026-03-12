part of '../tenant_admin_event.dart';

class TenantAdminEventPartyCandidates {
  const TenantAdminEventPartyCandidates({
    this.venues = const <TenantAdminAccountProfile>[],
    this.artists = const <TenantAdminAccountProfile>[],
  });

  final List<TenantAdminAccountProfile> venues;
  final List<TenantAdminAccountProfile> artists;
}
