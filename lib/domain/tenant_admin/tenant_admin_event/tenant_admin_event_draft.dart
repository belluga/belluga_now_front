part of '../tenant_admin_event.dart';

class TenantAdminEventDraft {
  TenantAdminEventDraft({
    required Object title,
    required Object content,
    required this.type,
    required this.occurrences,
    required this.publication,
    this.location,
    this.placeRef,
    Object? coverUrl,
    this.coverUpload,
    Object? removeCover,
    Object? artistIds,
    this.taxonomyTerms = const <TenantAdminTaxonomyTerm>[],
  })  : titleValue = tenantAdminRequiredText(title),
        contentValue = tenantAdminOptionalText(content),
        coverUrlValue = tenantAdminOptionalUrl(coverUrl),
        removeCoverValue = tenantAdminFlag(removeCover),
        artistIdValues = tenantAdminTrimmedStringList(artistIds);

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
  List<String> get artistIds => artistIdValues.value;
}
