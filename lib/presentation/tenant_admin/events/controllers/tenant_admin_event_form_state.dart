import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';

class TenantAdminEventFormState {
  static const Object _undefined = Object();

  const TenantAdminEventFormState({
    required this.startAt,
    required this.endAt,
    required this.publishAt,
    required this.locationMode,
    required this.publicationStatus,
    required this.selectedVenueId,
    required this.selectedTypeSlug,
    required this.selectedRelatedAccountProfileIds,
    required this.occurrences,
    required this.selectedTaxonomyTerms,
    required this.hasHydratedDefaultVenue,
  });

  factory TenantAdminEventFormState.initial() {
    return const TenantAdminEventFormState(
      startAt: null,
      endAt: null,
      publishAt: null,
      locationMode: 'physical',
      publicationStatus: 'draft',
      selectedVenueId: null,
      selectedTypeSlug: null,
      selectedRelatedAccountProfileIds: <String>[],
      occurrences: <TenantAdminEventOccurrence>[],
      selectedTaxonomyTerms: <String, Set<String>>{},
      hasHydratedDefaultVenue: false,
    );
  }

  final DateTime? startAt;
  final DateTime? endAt;
  final DateTime? publishAt;
  final String locationMode;
  final String publicationStatus;
  final String? selectedVenueId;
  final String? selectedTypeSlug;
  final List<String> selectedRelatedAccountProfileIds;
  final List<TenantAdminEventOccurrence> occurrences;
  final Map<String, Set<String>> selectedTaxonomyTerms;
  final bool hasHydratedDefaultVenue;

  TenantAdminEventFormState copyWith({
    Object? startAt = _undefined,
    Object? endAt = _undefined,
    Object? publishAt = _undefined,
    String? locationMode,
    String? publicationStatus,
    Object? selectedVenueId = _undefined,
    Object? selectedTypeSlug = _undefined,
    List<String>? selectedRelatedAccountProfileIds,
    List<TenantAdminEventOccurrence>? occurrences,
    Map<String, Set<String>>? selectedTaxonomyTerms,
    bool? hasHydratedDefaultVenue,
  }) {
    return TenantAdminEventFormState(
      startAt: startAt == _undefined ? this.startAt : startAt as DateTime?,
      endAt: endAt == _undefined ? this.endAt : endAt as DateTime?,
      publishAt:
          publishAt == _undefined ? this.publishAt : publishAt as DateTime?,
      locationMode: locationMode ?? this.locationMode,
      publicationStatus: publicationStatus ?? this.publicationStatus,
      selectedVenueId: selectedVenueId == _undefined
          ? this.selectedVenueId
          : selectedVenueId as String?,
      selectedTypeSlug: selectedTypeSlug == _undefined
          ? this.selectedTypeSlug
          : selectedTypeSlug as String?,
      selectedRelatedAccountProfileIds: selectedRelatedAccountProfileIds ??
          this.selectedRelatedAccountProfileIds,
      occurrences: occurrences ?? this.occurrences,
      selectedTaxonomyTerms:
          selectedTaxonomyTerms ?? this.selectedTaxonomyTerms,
      hasHydratedDefaultVenue:
          hasHydratedDefaultVenue ?? this.hasHydratedDefaultVenue,
    );
  }
}
