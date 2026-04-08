part of '../tenant_admin_event.dart';

class TenantAdminEventDraft {
  TenantAdminEventDraft({
    required this.titleValue,
    required this.contentValue,
    required this.type,
    required this.occurrences,
    required this.publication,
    this.location,
    this.placeRef,
    TenantAdminOptionalUrlValue? coverUrlValue,
    this.coverUpload,
    TenantAdminFlagValue? removeCoverValue,
    List<TenantAdminArtistIdValue>? artistIdValues,
    List<TenantAdminAccountProfile>? artistProfiles,
    TenantAdminTaxonomyTerms? taxonomyTerms,
  })  : coverUrlValue = coverUrlValue ?? TenantAdminOptionalUrlValue(),
        removeCoverValue = removeCoverValue ?? TenantAdminFlagValue(false),
        artistIdValues = List<TenantAdminArtistIdValue>.unmodifiable(
          artistIdValues ?? const <TenantAdminArtistIdValue>[],
        ),
        artistProfiles = List<TenantAdminAccountProfile>.unmodifiable(
          artistProfiles ?? const <TenantAdminAccountProfile>[],
        ),
        taxonomyTerms = taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty();

  final TenantAdminRequiredTextValue titleValue;
  final TenantAdminOptionalTextValue contentValue;
  final TenantAdminEventType type;
  final List<TenantAdminEventOccurrence> occurrences;
  final TenantAdminEventPublication publication;
  final TenantAdminEventLocation? location;
  final TenantAdminEventPlaceRef? placeRef;
  final TenantAdminOptionalUrlValue coverUrlValue;
  final TenantAdminMediaUpload? coverUpload;
  final TenantAdminFlagValue removeCoverValue;
  final List<TenantAdminArtistIdValue> artistIdValues;
  final List<TenantAdminAccountProfile> artistProfiles;
  final TenantAdminTaxonomyTerms taxonomyTerms;

  String get title => titleValue.value;
  String get content => contentValue.value;
  String? get coverUrl => coverUrlValue.nullableValue;
  bool get removeCover => removeCoverValue.value;
  List<TenantAdminArtistIdValue> get artistIds => artistIdValues;
}
