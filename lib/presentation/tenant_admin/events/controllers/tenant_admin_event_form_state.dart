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
      selectedRelatedAccountProfileIds: <String>{},
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
  final Set<String> selectedRelatedAccountProfileIds;
  final Map<String, Set<String>> selectedTaxonomyTerms;
  final bool hasHydratedDefaultVenue;

  TenantAdminEventFormState copyWith({
    DateTime? startAt,
    DateTime? endAt,
    DateTime? publishAt,
    String? locationMode,
    String? publicationStatus,
    Object? selectedVenueId = _undefined,
    Object? selectedTypeSlug = _undefined,
    Set<String>? selectedRelatedAccountProfileIds,
    Map<String, Set<String>>? selectedTaxonomyTerms,
    bool? hasHydratedDefaultVenue,
  }) {
    return TenantAdminEventFormState(
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      publishAt: publishAt ?? this.publishAt,
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
      selectedTaxonomyTerms:
          selectedTaxonomyTerms ?? this.selectedTaxonomyTerms,
      hasHydratedDefaultVenue:
          hasHydratedDefaultVenue ?? this.hasHydratedDefaultVenue,
    );
  }
}
