import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';

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

class TenantAdminEventDraft {
  const TenantAdminEventDraft({
    required this.title,
    required this.content,
    required this.type,
    required this.occurrences,
    required this.publication,
    this.location,
    this.placeRef,
    this.artistIds = const <String>[],
    this.taxonomyTerms = const <TenantAdminTaxonomyTerm>[],
  });

  final String title;
  final String content;
  final TenantAdminEventType type;
  final List<TenantAdminEventOccurrence> occurrences;
  final TenantAdminEventPublication publication;
  final TenantAdminEventLocation? location;
  final TenantAdminEventPlaceRef? placeRef;
  final List<String> artistIds;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
}

class TenantAdminEventType {
  const TenantAdminEventType({
    required this.name,
    required this.slug,
    this.id,
    this.description,
    this.icon,
    this.color,
  });

  final String name;
  final String slug;
  final String? id;
  final String? description;
  final String? icon;
  final String? color;
}

class TenantAdminEventOccurrence {
  const TenantAdminEventOccurrence({
    required this.dateTimeStart,
    this.dateTimeEnd,
    this.occurrenceId,
    this.occurrenceSlug,
  });

  final DateTime dateTimeStart;
  final DateTime? dateTimeEnd;
  final String? occurrenceId;
  final String? occurrenceSlug;
}

class TenantAdminEventPublication {
  const TenantAdminEventPublication({
    required this.status,
    this.publishAt,
  });

  final String status;
  final DateTime? publishAt;
}

class TenantAdminEventLocation {
  const TenantAdminEventLocation({
    required this.mode,
    this.latitude,
    this.longitude,
    this.online,
  });

  final String mode;
  final double? latitude;
  final double? longitude;
  final TenantAdminEventOnlineLocation? online;
}

class TenantAdminEventOnlineLocation {
  const TenantAdminEventOnlineLocation({
    required this.url,
    this.platform,
    this.label,
  });

  final String url;
  final String? platform;
  final String? label;
}

class TenantAdminEventPlaceRef {
  const TenantAdminEventPlaceRef({
    required this.type,
    required this.id,
    this.metadata,
  });

  final String type;
  final String id;
  final Map<String, dynamic>? metadata;
}

class TenantAdminEventParty {
  const TenantAdminEventParty({
    required this.partyType,
    required this.partyRefId,
    required this.canEdit,
    this.metadata,
  });

  final String partyType;
  final String partyRefId;
  final bool canEdit;
  final Map<String, dynamic>? metadata;
}

class TenantAdminEventPartyCandidates {
  const TenantAdminEventPartyCandidates({
    this.venues = const <TenantAdminAccountProfile>[],
    this.artists = const <TenantAdminAccountProfile>[],
  });

  final List<TenantAdminAccountProfile> venues;
  final List<TenantAdminAccountProfile> artists;
}
