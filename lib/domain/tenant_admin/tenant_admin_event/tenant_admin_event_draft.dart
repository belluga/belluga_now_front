part of '../tenant_admin_event.dart';

class TenantAdminEventDraft {
  const TenantAdminEventDraft({
    required this.title,
    required this.content,
    required this.type,
    required this.occurrences,
    required this.publication,
    this.location,
    this.placeRef,
    this.coverUrl,
    this.coverUpload,
    this.removeCover = false,
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
  final String? coverUrl;
  final TenantAdminMediaUpload? coverUpload;
  final bool removeCover;
  final List<String> artistIds;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
}
