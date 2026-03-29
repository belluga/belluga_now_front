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
    TenantAdminTrimmedStringListValue? artistIdValues,
    this.taxonomyTerms = const <TenantAdminTaxonomyTerm>[],
  })  : coverUrlValue = coverUrlValue ?? TenantAdminOptionalUrlValue(),
        removeCoverValue = removeCoverValue ?? const TenantAdminFlagValue(false),
        artistIdValues = artistIdValues ?? TenantAdminTrimmedStringListValue();

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
  final TenantAdminTrimmedStringListValue artistIdValues;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;

  String get title => titleValue.value;
  String get content => contentValue.value;
  String? get coverUrl => coverUrlValue.nullableValue;
  bool get removeCover => removeCoverValue.value;
  TenantAdminTrimmedStringListValue get artistIds => artistIdValues;
}
