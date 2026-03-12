import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';

part 'tenant_admin_event/tenant_admin_event_draft.dart';
part 'tenant_admin_event/tenant_admin_event_location.dart';
part 'tenant_admin_event/tenant_admin_event_occurrence.dart';
part 'tenant_admin_event/tenant_admin_event_online_location.dart';
part 'tenant_admin_event/tenant_admin_event_party.dart';
part 'tenant_admin_event/tenant_admin_event_party_candidates.dart';
part 'tenant_admin_event/tenant_admin_event_place_ref.dart';
part 'tenant_admin_event/tenant_admin_event_publication.dart';
part 'tenant_admin_event/tenant_admin_event_type.dart';

class TenantAdminEvent {
  const TenantAdminEvent({
    required this.eventId,
    required this.slug,
    required this.title,
    required this.content,
    required this.type,
    required this.occurrences,
    required this.publication,
    this.location,
    this.placeRef,
    this.artistIds = const <String>[],
    this.eventParties = const <TenantAdminEventParty>[],
    this.taxonomyTerms = const <TenantAdminTaxonomyTerm>[],
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String eventId;
  final String slug;
  final String title;
  final String content;
  final TenantAdminEventType type;
  final TenantAdminEventLocation? location;
  final TenantAdminEventPlaceRef? placeRef;
  final List<TenantAdminEventOccurrence> occurrences;
  final TenantAdminEventPublication publication;
  final List<String> artistIds;
  final List<TenantAdminEventParty> eventParties;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
}
