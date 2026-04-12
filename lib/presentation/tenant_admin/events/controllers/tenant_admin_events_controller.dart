export 'tenant_admin_event_form_state.dart';
export 'tenant_admin_event_type_form_state.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_temporal_bucket.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_legacy_event_parties_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_event_form_state.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_event_type_form_state.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:image_picker/image_picker.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminEventsController implements Disposable {
  TenantAdminEventsController({
    TenantAdminEventsRepositoryContract? eventsRepository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminTenantScopeContract? tenantScope,
    LandlordAuthRepositoryContract? landlordAuthRepository,
    TenantAdminImageIngestionService? imageIngestionService,
  })  : _eventsRepository = eventsRepository ??
            GetIt.I.get<TenantAdminEventsRepositoryContract>(),
        _taxonomiesRepository = taxonomiesRepository ??
            GetIt.I.get<TenantAdminTaxonomiesRepositoryContract>(),
        _tenantScope = tenantScope ??
            (GetIt.I.isRegistered<TenantAdminTenantScopeContract>()
                ? GetIt.I.get<TenantAdminTenantScopeContract>()
                : null),
        _landlordAuthRepository = landlordAuthRepository ??
            (GetIt.I.isRegistered<LandlordAuthRepositoryContract>()
                ? GetIt.I.get<LandlordAuthRepositoryContract>()
                : null),
        _imageIngestionService = imageIngestionService ??
            (GetIt.I.isRegistered<TenantAdminImageIngestionService>()
                ? GetIt.I.get<TenantAdminImageIngestionService>()
                : TenantAdminImageIngestionService()) {
    _bindTenantScope();
    _bindRepositoryStreams();
    _bindRelatedAccountProfileSearchScroll();
  }

  final TenantAdminEventsRepositoryContract _eventsRepository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminTenantScopeContract? _tenantScope;
  final LandlordAuthRepositoryContract? _landlordAuthRepository;
  final TenantAdminImageIngestionService _imageIngestionService;

  StreamValue<List<TenantAdminEvent>?> get eventsStreamValue =>
      _eventsRepository.eventsStreamValue;
  final StreamValue<bool> hasMoreEventsStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<bool> isEventsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> eventsErrorStreamValue = StreamValue<String?>();

  final StreamValue<String?> statusFilterStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<bool> archivedFilterStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<Set<TenantAdminEventTemporalBucket>>
      temporalFilterStreamValue =
      StreamValue<Set<TenantAdminEventTemporalBucket>>(
    defaultValue: TenantAdminEventTemporalBucket.defaultSelection,
  );

  final StreamValue<TenantAdminEvent?> eventDetailStreamValue =
      StreamValue<TenantAdminEvent?>();
  final StreamValue<bool> eventDetailLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> eventDetailErrorStreamValue =
      StreamValue<String?>();

  final StreamValue<bool> submitLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> submitErrorMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<String?> submitSuccessMessageStreamValue =
      StreamValue<String?>();
  final StreamValue<List<TenantAdminEventType>> eventTypeCatalogStreamValue =
      StreamValue<List<TenantAdminEventType>>(defaultValue: const []);

  final StreamValue<List<TenantAdminTaxonomyDefinition>> taxonomiesStreamValue =
      StreamValue<List<TenantAdminTaxonomyDefinition>>(defaultValue: const []);

  final StreamValue<Map<String, List<TenantAdminTaxonomyTermDefinition>>>
      taxonomyTermsBySlugStreamValue =
      StreamValue<Map<String, List<TenantAdminTaxonomyTermDefinition>>>(
    defaultValue: const {},
  );

  final StreamValue<bool> taxonomyLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> taxonomyErrorStreamValue = StreamValue<String?>();

  final StreamValue<List<TenantAdminAccountProfile>>
      venueCandidatesStreamValue =
      StreamValue<List<TenantAdminAccountProfile>>(defaultValue: const []);
  final StreamValue<List<TenantAdminAccountProfile>>
      relatedAccountProfileCandidatesStreamValue =
      StreamValue<List<TenantAdminAccountProfile>>(defaultValue: const []);
  final StreamValue<List<TenantAdminAccountProfile>>
      relatedAccountProfileSearchResultsStreamValue =
      StreamValue<List<TenantAdminAccountProfile>>(defaultValue: const []);
  final StreamValue<bool> relatedAccountProfileSearchLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> relatedAccountProfileSearchPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> relatedAccountProfileSearchHasMoreStreamValue =
      StreamValue<bool>(defaultValue: true);
  final StreamValue<String> relatedAccountProfileSearchErrorStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<String> relatedAccountProfileSearchQueryStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<bool> accountProfileCandidatesLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> accountProfileCandidatesErrorStreamValue =
      StreamValue<String?>();

  final ScrollController eventsScrollController = ScrollController();
  final ScrollController relatedAccountProfileSearchScrollController =
      ScrollController();

  final GlobalKey<FormState> eventFormKey = GlobalKey<FormState>();
  final TextEditingController relatedAccountProfileSearchController =
      TextEditingController();
  final TextEditingController eventTitleController = TextEditingController();
  final TextEditingController eventContentController = TextEditingController();
  final TextEditingController eventStartController = TextEditingController();
  final TextEditingController eventEndController = TextEditingController();
  final TextEditingController eventPublishAtController =
      TextEditingController();
  final TextEditingController eventOnlineUrlController =
      TextEditingController();
  final TextEditingController eventOnlinePlatformController =
      TextEditingController();
  final StreamValue<XFile?> eventCoverFileStreamValue =
      StreamValue<XFile?>(defaultValue: null);
  final StreamValue<bool> eventCoverBusyStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<bool> eventCoverRemoveStreamValue =
      StreamValue<bool>(defaultValue: false);

  final StreamValue<TenantAdminEventFormState> eventFormStateStreamValue =
      StreamValue<TenantAdminEventFormState>(
    defaultValue: TenantAdminEventFormState.initial(),
  );

  final GlobalKey<FormState> eventTypeFormKey = GlobalKey<FormState>();
  final TextEditingController eventTypeNameController = TextEditingController();
  final TextEditingController eventTypeSlugController = TextEditingController();
  final TextEditingController eventTypeDescriptionController =
      TextEditingController();
  final StreamValue<TenantAdminPoiVisualMode>
      eventTypePoiVisualModeStreamValue = StreamValue<TenantAdminPoiVisualMode>(
    defaultValue: TenantAdminPoiVisualMode.icon,
  );
  final StreamValue<TenantAdminPoiVisualImageSource>
      eventTypePoiVisualImageSourceStreamValue =
      StreamValue<TenantAdminPoiVisualImageSource>(
    defaultValue: TenantAdminPoiVisualImageSource.cover,
  );
  final TextEditingController eventTypePoiVisualIconController =
      TextEditingController();
  final TextEditingController eventTypePoiVisualColorController =
      TextEditingController();
  final TextEditingController eventTypePoiVisualIconColorController =
      TextEditingController();
  final StreamValue<XFile?> eventTypeTypeAssetFileStreamValue =
      StreamValue<XFile?>(defaultValue: null);
  final StreamValue<String> eventTypeTypeAssetUrlStreamValue =
      StreamValue<String>(defaultValue: '');
  final StreamValue<bool> eventTypeRemoveTypeAssetStreamValue =
      StreamValue<bool>(defaultValue: false);

  final StreamValue<TenantAdminEventTypeFormState>
      eventTypeFormStateStreamValue =
      StreamValue<TenantAdminEventTypeFormState>(
    defaultValue: TenantAdminEventTypeFormState.initial(),
  );

  bool _isDisposed = false;
  bool _submitInFlight = false;
  bool _isFetchingRelatedAccountProfileSearchPage = false;
  bool _hasPendingRelatedAccountProfileSearchReload = false;
  StreamSubscription<String?>? _tenantScopeSubscription;
  StreamSubscription<TenantAdminEventsRepoBool>? _hasMoreEventsSubscription;
  StreamSubscription<TenantAdminEventsRepoBool>?
      _isEventsPageLoadingSubscription;
  StreamSubscription<TenantAdminEventsRepoString?>? _eventsErrorSubscription;
  String? _lastTenantDomain;
  VoidCallback? _eventTypeNameSyncListener;
  Timer? _relatedAccountProfileSearchDebounce;
  String? _relatedAccountProfileSearchAccountSlug;
  int _relatedAccountProfileSearchCurrentPage = 0;
  int _relatedAccountProfileSearchRequestToken = 0;

  static const Duration _relatedAccountProfileSearchDebounceDuration =
      Duration(milliseconds: 300);
  void _bindTenantScope() {
    if (_tenantScopeSubscription != null || _tenantScope == null) {
      return;
    }
    final tenantScope = _tenantScope;
    _lastTenantDomain =
        _normalizeTenantDomain(tenantScope.selectedTenantDomain);
    _tenantScopeSubscription = tenantScope
        .selectedTenantDomainStreamValue.stream
        .listen((tenantDomain) {
      if (_isDisposed) {
        return;
      }
      final normalized = _normalizeTenantDomain(tenantDomain);
      if (normalized == _lastTenantDomain) {
        return;
      }
      _lastTenantDomain = normalized;
      _resetTenantScopedState();
      if (normalized != null) {
        unawaited(loadEvents());
      }
    });
  }

  void _bindRepositoryStreams() {
    hasMoreEventsStreamValue
        .addValue(_eventsRepository.hasMoreEventsStreamValue.value.value);
    isEventsPageLoadingStreamValue.addValue(
      _eventsRepository.isEventsPageLoadingStreamValue.value.value,
    );
    eventsErrorStreamValue.addValue(
      _eventsRepository.eventsErrorStreamValue.value?.value,
    );

    _hasMoreEventsSubscription =
        _eventsRepository.hasMoreEventsStreamValue.stream.listen((value) {
      if (_isDisposed) {
        return;
      }
      hasMoreEventsStreamValue.addValue(value.value);
    });

    _isEventsPageLoadingSubscription =
        _eventsRepository.isEventsPageLoadingStreamValue.stream.listen((value) {
      if (_isDisposed) {
        return;
      }
      isEventsPageLoadingStreamValue.addValue(value.value);
    });

    _eventsErrorSubscription =
        _eventsRepository.eventsErrorStreamValue.stream.listen((value) {
      if (_isDisposed) {
        return;
      }
      eventsErrorStreamValue.addValue(value?.value);
    });
  }

  TenantAdminEventsRepoString _toEventsText(String value) {
    return TenantAdminEventsRepoString.fromRaw(
      value,
      defaultValue: value,
    );
  }

  TenantAdminEventsRepoString? _toNullableEventsText(String? value) {
    if (value == null) {
      return null;
    }
    return _toEventsText(value);
  }

  TenantAdminEventsRepoBool _toEventsBool(bool value) {
    return TenantAdminEventsRepoBool.fromRaw(
      value,
      defaultValue: value,
    );
  }

  String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  TenantAdminOptionalUrlValue? _buildOptionalUrlValue(String? value) {
    final normalized = _normalizeOptionalText(value);
    if (normalized == null) {
      return null;
    }
    final urlValue = TenantAdminOptionalUrlValue();
    urlValue.parse(normalized);
    return urlValue;
  }

  Future<void> loadEvents() async {
    if (_isDisposed) {
      return;
    }
    if (!_hasLandlordToken()) {
      _eventsRepository.resetEventsState();
      _eventsRepository.setEventsState(const <TenantAdminEvent>[]);
      return;
    }
    await _eventsRepository.loadEvents(
      status: _toNullableEventsText(statusFilterStreamValue.value),
      archived: _toEventsBool(archivedFilterStreamValue.value),
      temporalBuckets: temporalFilterStreamValue.value,
    );
  }

  Future<void> loadNextEventsPage() async {
    if (_isDisposed) {
      return;
    }
    if (!_hasLandlordToken()) {
      return;
    }
    await _eventsRepository.loadNextEventsPage(
      status: _toNullableEventsText(statusFilterStreamValue.value),
      archived: _toEventsBool(archivedFilterStreamValue.value),
      temporalBuckets: temporalFilterStreamValue.value,
    );
  }

  void updateStatusFilter(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      statusFilterStreamValue.addValue(null);
      return;
    }
    statusFilterStreamValue.addValue(normalized);
  }

  void updateArchivedFilter(bool archivedOnly) {
    archivedFilterStreamValue.addValue(archivedOnly);
  }

  void toggleTemporalFilter(TenantAdminEventTemporalBucket bucket) {
    final current = Set<TenantAdminEventTemporalBucket>.from(
      temporalFilterStreamValue.value,
    );
    if (current.contains(bucket)) {
      if (current.length == 1) {
        return;
      }
      current.remove(bucket);
    } else {
      current.add(bucket);
    }
    temporalFilterStreamValue.addValue(Set.unmodifiable(current));
  }

  Future<void> applyFilters() async {
    await loadEvents();
  }

  void initEventForm({
    TenantAdminEvent? existingEvent,
  }) {
    final firstOccurrence = existingEvent?.occurrences.firstOrNull;
    final selectedTaxonomyTerms = <String, Set<String>>{};
    for (final term in existingEvent?.taxonomyTerms ??
        const TenantAdminTaxonomyTerms.empty()) {
      final bucket =
          selectedTaxonomyTerms.putIfAbsent(term.type, () => <String>{});
      bucket.add(term.value);
    }
    final nextState = TenantAdminEventFormState(
      startAt: firstOccurrence?.dateTimeStart == null
          ? null
          : TimezoneConverter.utcToLocal(firstOccurrence!.dateTimeStart),
      endAt: firstOccurrence?.dateTimeEnd == null
          ? null
          : TimezoneConverter.utcToLocal(firstOccurrence!.dateTimeEnd!),
      publishAt: existingEvent?.publication.publishAt == null
          ? null
          : TimezoneConverter.utcToLocal(existingEvent!.publication.publishAt!),
      locationMode: existingEvent?.location?.mode ?? 'physical',
      publicationStatus: existingEvent?.publication.status ?? 'draft',
      selectedVenueId: existingEvent?.placeRef?.id,
      selectedTypeSlug: existingEvent?.type.slug.trim(),
      selectedRelatedAccountProfileIds: {
        ...?existingEvent?.eventParties
            .where((party) => party.partyType != 'venue')
            .map((party) => party.partyRefId),
      },
      selectedTaxonomyTerms: selectedTaxonomyTerms,
      hasHydratedDefaultVenue: false,
    );

    eventTitleController.text = existingEvent?.title ?? '';
    eventContentController.text = existingEvent?.content ?? '';
    eventOnlineUrlController.text = existingEvent?.location?.online?.url ?? '';
    eventOnlinePlatformController.text =
        existingEvent?.location?.online?.platform ?? '';
    eventCoverFileStreamValue.addValue(null);
    eventCoverBusyStreamValue.addValue(false);
    eventCoverRemoveStreamValue.addValue(false);
    _mergeKnownRelatedAccountProfiles(
      existingEvent?.relatedAccountProfiles ?? const [],
    );
    _replaceEventFormState(nextState);
    _syncEventDateTimeControllers(nextState);
  }

  Future<XFile?> pickImageFromDevice({
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.pickFromDevice(slot: slot);
  }

  Future<XFile> fetchImageFromUrlForCrop({
    required String imageUrl,
  }) {
    return _imageIngestionService.fetchFromUrlForCrop(imageUrl: imageUrl);
  }

  Future<Uint8List> readImageBytesForCrop(XFile sourceFile) {
    return _imageIngestionService.readBytesForCrop(sourceFile);
  }

  Future<XFile> prepareCroppedImage(
    Uint8List croppedData, {
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.prepareBytesAsXFile(
      croppedData,
      slot: slot,
      applyAspectCrop: false,
    );
  }

  Future<TenantAdminMediaUpload?> buildImageUpload(
    XFile? file, {
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.buildUpload(file, slot: slot);
  }

  void updateEventCoverFile(XFile? file) {
    eventCoverFileStreamValue.addValue(file);
    if (file != null) {
      eventCoverRemoveStreamValue.addValue(false);
    }
  }

  void setEventCoverBusy(bool isBusy) {
    eventCoverBusyStreamValue.addValue(isBusy);
  }

  void removeEventCover() {
    eventCoverFileStreamValue.addValue(null);
    eventCoverRemoveStreamValue.addValue(true);
  }

  void restoreEventCover() {
    eventCoverRemoveStreamValue.addValue(false);
  }

  void updateEventTypeSelection(String? slug) {
    _replaceEventFormState(
      eventFormStateStreamValue.value.copyWith(
        selectedTypeSlug: slug,
      ),
    );
  }

  void updateEventPublicationStatus(String status) {
    final current = eventFormStateStreamValue.value;
    var nextPublishAt = current.publishAt;
    if (status != 'publish_scheduled') {
      nextPublishAt = null;
    }
    final nextState = current.copyWith(
      publicationStatus: status,
      publishAt: nextPublishAt,
    );
    _replaceEventFormState(nextState);
    _syncEventDateTimeControllers(nextState);
  }

  void updateEventLocationMode(String mode) {
    final current = eventFormStateStreamValue.value;
    if (mode == current.locationMode) {
      return;
    }
    if (mode == 'physical') {
      eventOnlineUrlController.clear();
      eventOnlinePlatformController.clear();
    }
    _replaceEventFormState(
      current.copyWith(locationMode: mode),
    );
  }

  void updateEventVenueSelection(String? venueId) {
    _replaceEventFormState(
      eventFormStateStreamValue.value.copyWith(selectedVenueId: venueId),
    );
  }

  void addRelatedAccountProfile(String profileId) {
    final current = eventFormStateStreamValue.value;
    final next = {...current.selectedRelatedAccountProfileIds, profileId};
    _replaceEventFormState(
      current.copyWith(selectedRelatedAccountProfileIds: next),
    );
  }

  void removeRelatedAccountProfile(String profileId) {
    final current = eventFormStateStreamValue.value;
    if (!current.selectedRelatedAccountProfileIds.contains(profileId)) {
      return;
    }
    final next = {...current.selectedRelatedAccountProfileIds}
      ..remove(profileId);
    _replaceEventFormState(
      current.copyWith(selectedRelatedAccountProfileIds: next),
    );
  }

  void toggleEventTaxonomyTerm({
    required String taxonomySlug,
    required String termSlug,
    required bool isSelected,
  }) {
    final current = eventFormStateStreamValue.value;
    final next = <String, Set<String>>{
      for (final entry in current.selectedTaxonomyTerms.entries)
        entry.key: {...entry.value},
    };
    final bucket = next.putIfAbsent(taxonomySlug, () => <String>{});
    if (isSelected) {
      bucket.add(termSlug);
    } else {
      bucket.remove(termSlug);
      if (bucket.isEmpty) {
        next.remove(taxonomySlug);
      }
    }
    _replaceEventFormState(
      current.copyWith(selectedTaxonomyTerms: next),
    );
  }

  void applyEventStartAt(DateTime value) {
    final current = eventFormStateStreamValue.value;
    var nextEndAt = current.endAt;
    if (nextEndAt != null && nextEndAt.isBefore(value)) {
      nextEndAt = value;
    }
    final nextState = current.copyWith(
      startAt: value,
      endAt: nextEndAt,
    );
    _replaceEventFormState(nextState);
    _syncEventDateTimeControllers(nextState);
  }

  void applyEventEndAt(DateTime value) {
    final nextState = eventFormStateStreamValue.value.copyWith(endAt: value);
    _replaceEventFormState(nextState);
    _syncEventDateTimeControllers(nextState);
  }

  void clearEventEndAt() {
    final nextState = eventFormStateStreamValue.value.copyWith(endAt: null);
    _replaceEventFormState(nextState);
    _syncEventDateTimeControllers(nextState);
  }

  void applyEventPublishAt(DateTime value) {
    final nextState =
        eventFormStateStreamValue.value.copyWith(publishAt: value);
    _replaceEventFormState(nextState);
    _syncEventDateTimeControllers(nextState);
  }

  void clearEventPublishAt() {
    final nextState = eventFormStateStreamValue.value.copyWith(publishAt: null);
    _replaceEventFormState(nextState);
    _syncEventDateTimeControllers(nextState);
  }

  void hydrateDefaultEventVenue(List<TenantAdminAccountProfile> venues) {
    final current = eventFormStateStreamValue.value;
    if (current.hasHydratedDefaultVenue) {
      return;
    }
    if (current.selectedVenueId != null &&
        venues.any((venue) => venue.id == current.selectedVenueId)) {
      _replaceEventFormState(
        current.copyWith(hasHydratedDefaultVenue: true),
      );
      return;
    }
    if ((current.locationMode == 'physical' ||
            current.locationMode == 'hybrid') &&
        venues.isNotEmpty) {
      _replaceEventFormState(
        current.copyWith(
          selectedVenueId: venues.first.id,
          hasHydratedDefaultVenue: true,
        ),
      );
      return;
    }
    _replaceEventFormState(
      current.copyWith(hasHydratedDefaultVenue: true),
    );
  }

  void hydrateDefaultEventType(List<TenantAdminEventType> eventTypes) {
    final current = eventFormStateStreamValue.value;
    if (eventTypes.isEmpty) {
      final selectedTypeSlug = current.selectedTypeSlug?.trim();
      if (selectedTypeSlug == null || selectedTypeSlug.isEmpty) {
        return;
      }
      _replaceEventFormState(
        current.copyWith(selectedTypeSlug: null),
      );
      return;
    }
    final selectedTypeSlug = current.selectedTypeSlug?.trim();
    if (selectedTypeSlug != null &&
        selectedTypeSlug.isNotEmpty &&
        eventTypes.any((type) => type.slug.trim() == selectedTypeSlug)) {
      return;
    }
    _replaceEventFormState(
      current.copyWith(selectedTypeSlug: eventTypes.first.slug.trim()),
    );
  }

  void initEventTypeForm({
    TenantAdminEventType? existingType,
  }) {
    if (_eventTypeNameSyncListener != null) {
      eventTypeNameController.removeListener(_eventTypeNameSyncListener!);
      _eventTypeNameSyncListener = null;
    }

    final isEdit = existingType != null;
    eventTypeNameController.text = existingType?.name ?? '';
    eventTypeSlugController.text = existingType?.slug ?? '';
    eventTypeDescriptionController.text = existingType?.description ?? '';
    _syncEventTypeVisualForm(existingType?.visual);

    final nextState = TenantAdminEventTypeFormState(
      isEdit: isEdit,
      isSlugAutoEnabled: !isEdit,
      isSaving: false,
      formError: null,
    );
    eventTypeFormStateStreamValue.addValue(nextState);
    if (!isEdit) {
      _eventTypeNameSyncListener = _syncEventTypeSlugFromName;
      eventTypeNameController.addListener(_eventTypeNameSyncListener!);
      _syncEventTypeSlugFromName();
    }
  }

  void updateEventTypeSlugAutoFlagFromManualInput(String value) {
    final current = eventTypeFormStateStreamValue.value;
    if (current.isEdit || !current.isSlugAutoEnabled) {
      return;
    }
    final generated = _tenantAdminSlugify(eventTypeNameController.text);
    if (value == generated) {
      return;
    }
    eventTypeFormStateStreamValue.addValue(
      current.copyWith(isSlugAutoEnabled: false),
    );
  }

  void setEventTypeFormSaving(bool value) {
    eventTypeFormStateStreamValue.addValue(
      eventTypeFormStateStreamValue.value.copyWith(isSaving: value),
    );
  }

  void setEventTypeFormError(String? value) {
    eventTypeFormStateStreamValue.addValue(
      eventTypeFormStateStreamValue.value.copyWith(formError: value),
    );
  }

  Future<TenantAdminEventType> saveEventType({
    required String name,
    required String slug,
    String? description,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    bool removeTypeAsset = false,
    bool includeVisual = false,
    TenantAdminEventType? existingType,
  }) async {
    final normalizedName = name.trim();
    final normalizedSlug = slug.trim();
    final normalizedDescription = description?.trim();
    final descriptionForCreate =
        (normalizedDescription == null || normalizedDescription.isEmpty)
            ? null
            : normalizedDescription;
    final descriptionForUpdate =
        (normalizedDescription == null || normalizedDescription.isEmpty)
            ? null
            : normalizedDescription;

    final eventTypeId = existingType?.id?.trim();
    final isEdit = eventTypeId != null && eventTypeId.isNotEmpty;

    final saved = isEdit
        ? includeVisual
            ? await _eventsRepository.updateEventTypeWithVisual(
                eventTypeId: _toEventsText(eventTypeId),
                name: _toEventsText(normalizedName),
                slug: _toEventsText(normalizedSlug),
                description: _toNullableEventsText(descriptionForUpdate),
                visual: visual,
                typeAssetUpload: typeAssetUpload,
                removeTypeAsset: TenantAdminEventsRepoBool.fromRaw(
                  removeTypeAsset,
                  defaultValue: false,
                ),
              )
            : await _eventsRepository.updateEventType(
                eventTypeId: _toEventsText(eventTypeId),
                name: _toEventsText(normalizedName),
                slug: _toEventsText(normalizedSlug),
                description: _toNullableEventsText(descriptionForUpdate),
              )
        : includeVisual
            ? await _eventsRepository.createEventTypeWithVisual(
                name: _toEventsText(normalizedName),
                slug: _toEventsText(normalizedSlug),
                description: _toNullableEventsText(descriptionForCreate),
                visual: visual,
                typeAssetUpload: typeAssetUpload,
              )
            : await _eventsRepository.createEventType(
                name: _toEventsText(normalizedName),
                slug: _toEventsText(normalizedSlug),
                description: _toNullableEventsText(descriptionForCreate),
              );

    await _loadEventTypeCatalog();
    return saved;
  }

  Future<void> submitDeleteEventType(TenantAdminEventType type) async {
    final eventTypeId = type.id?.trim();
    if (eventTypeId == null || eventTypeId.isEmpty) {
      throw const FormatException(
        'Event type id is required to delete this entry.',
      );
    }

    await _eventsRepository.deleteEventType(_toEventsText(eventTypeId));
    await _loadEventTypeCatalog();
  }

  Future<void> loadEventDetail(String eventIdOrSlug) async {
    eventDetailLoadingStreamValue.addValue(true);
    eventDetailErrorStreamValue.addValue(null);
    try {
      final event = await _eventsRepository.fetchEvent(
        _toEventsText(eventIdOrSlug),
      );
      if (_isDisposed) {
        return;
      }
      eventDetailStreamValue.addValue(event);
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      eventDetailErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        eventDetailLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> loadFormDependencies({
    String? accountSlug,
  }) async {
    final normalizedAccountSlug = _normalizeOptionalText(accountSlug);
    final tasks = <Future<void>>[
      _loadEventTypeCatalog(),
      _loadTaxonomies(),
      _loadAccountProfileCandidates(accountSlug: normalizedAccountSlug),
    ];

    await Future.wait<void>(tasks);
  }

  Future<void> _loadEventTypeCatalog() async {
    try {
      final eventTypes = await _eventsRepository.fetchEventTypes();
      if (_isDisposed) {
        return;
      }
      final sorted = eventTypes.toList(growable: false)
        ..sort(
          (left, right) => left.name.toLowerCase().compareTo(
                right.name.toLowerCase(),
              ),
        );
      eventTypeCatalogStreamValue.addValue(List.unmodifiable(sorted));
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      submitErrorMessageStreamValue.addValue(error.toString());
    }
  }

  Future<void> _loadTaxonomies() async {
    taxonomyLoadingStreamValue.addValue(true);
    try {
      await _taxonomiesRepository.loadAllTaxonomies();
      final taxonomies = _taxonomiesRepository.taxonomiesStreamValue.value ??
          const <TenantAdminTaxonomyDefinition>[];
      final filtered = taxonomies
          .where((taxonomy) => taxonomy.appliesToEvent())
          .toList(growable: false);
      if (_isDisposed) {
        return;
      }
      taxonomiesStreamValue.addValue(filtered);

      final entries =
          <MapEntry<String, List<TenantAdminTaxonomyTermDefinition>>>[];
      for (final taxonomy in filtered) {
        await _taxonomiesRepository.loadAllTerms(
            taxonomyId: TenantAdminTaxRepoString.fromRaw(taxonomy.id,
                defaultValue: '', isRequired: true));
        final terms = _taxonomiesRepository.termsStreamValue.value ??
            const <TenantAdminTaxonomyTermDefinition>[];
        entries.add(
          MapEntry<String, List<TenantAdminTaxonomyTermDefinition>>(
            taxonomy.slug,
            terms,
          ),
        );
      }

      if (_isDisposed) {
        return;
      }
      taxonomyTermsBySlugStreamValue.addValue({
        for (final entry in entries) entry.key: entry.value,
      });
      taxonomyErrorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      taxonomyErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        taxonomyLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> prepareRelatedAccountProfilePicker({
    String? accountSlug,
  }) async {
    final normalizedAccountSlug = _normalizeOptionalText(accountSlug);
    final accountChanged =
        normalizedAccountSlug != _relatedAccountProfileSearchAccountSlug;
    final hasSearch =
        relatedAccountProfileSearchQueryStreamValue.value.trim().isNotEmpty;
    final needsInitialLoad = _relatedAccountProfileSearchCurrentPage <= 0 &&
        relatedAccountProfileSearchResultsStreamValue.value.isEmpty;

    _relatedAccountProfileSearchAccountSlug = normalizedAccountSlug;
    if (relatedAccountProfileSearchController.text.isNotEmpty) {
      relatedAccountProfileSearchController.text = '';
    }
    relatedAccountProfileSearchQueryStreamValue.addValue('');
    relatedAccountProfileSearchErrorStreamValue.addValue('');

    if (relatedAccountProfileSearchScrollController.hasClients) {
      relatedAccountProfileSearchScrollController.jumpTo(0);
    }

    if (accountChanged || hasSearch || needsInitialLoad) {
      await _reloadRelatedAccountProfileSearch(immediate: true);
    }
  }

  void updateRelatedAccountProfileSearchQuery(String query) {
    if (relatedAccountProfileSearchQueryStreamValue.value == query) {
      return;
    }
    relatedAccountProfileSearchQueryStreamValue.addValue(query);
    _scheduleRelatedAccountProfileSearchReload(immediate: false);
  }

  Future<void> retryRelatedAccountProfileSearch() async {
    await _reloadRelatedAccountProfileSearch(immediate: true);
  }

  Future<void> loadNextRelatedAccountProfileSearchPage() async {
    await _loadRelatedAccountProfileSearchPage(
      isInitial: false,
      requestToken: _relatedAccountProfileSearchRequestToken,
    );
  }

  Future<void> _loadAccountProfileCandidates({
    String? accountSlug,
  }) async {
    final normalizedAccountSlug = _normalizeOptionalText(accountSlug);
    accountProfileCandidatesLoadingStreamValue.addValue(true);
    accountProfileCandidatesErrorStreamValue.addValue(null);

    try {
      final results = await Future.wait<Object>([
        _fetchAllPhysicalHostCandidates(accountSlug: normalizedAccountSlug),
        _eventsRepository.loadEventAccountProfileCandidates(
          candidateType:
              TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
          accountSlug: _toNullableEventsText(normalizedAccountSlug),
        ),
      ]);

      if (_isDisposed) {
        return;
      }

      final venues = results[0] as List<TenantAdminAccountProfile>;
      final firstRelatedAccountProfilePage =
          results[1] as TenantAdminPagedResult<TenantAdminAccountProfile>;

      venueCandidatesStreamValue.addValue(List.unmodifiable(venues));
      _relatedAccountProfileSearchAccountSlug = normalizedAccountSlug;
      _relatedAccountProfileSearchCurrentPage = 1;
      relatedAccountProfileSearchResultsStreamValue.addValue(
        List.unmodifiable(firstRelatedAccountProfilePage.items),
      );
      relatedAccountProfileSearchHasMoreStreamValue
          .addValue(firstRelatedAccountProfilePage.hasMore);
      relatedAccountProfileSearchErrorStreamValue.addValue('');
      _mergeKnownRelatedAccountProfiles(firstRelatedAccountProfilePage.items);
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      relatedAccountProfileSearchResultsStreamValue.addValue(const []);
      relatedAccountProfileSearchHasMoreStreamValue.addValue(false);
      relatedAccountProfileSearchErrorStreamValue.addValue(error.toString());
      accountProfileCandidatesErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        accountProfileCandidatesLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<List<TenantAdminAccountProfile>> _fetchAllPhysicalHostCandidates({
    String? accountSlug,
  }) async {
    return _eventsRepository.fetchAllEventAccountProfileCandidates(
      candidateType: TenantAdminEventAccountProfileCandidateType.physicalHost,
      accountSlug: _toNullableEventsText(accountSlug),
    );
  }

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
      _loadRelatedAccountProfileCandidates({
    required bool isInitial,
    required String query,
    String? accountSlug,
  }) {
    final normalizedQuery = query.trim();
    if (isInitial) {
      return _eventsRepository.loadEventAccountProfileCandidates(
        candidateType:
            TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
        search: normalizedQuery.isEmpty ? null : _toEventsText(normalizedQuery),
        accountSlug: _toNullableEventsText(accountSlug),
      );
    }

    return _eventsRepository.loadNextEventAccountProfileCandidates(
      candidateType:
          TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
      search: normalizedQuery.isEmpty ? null : _toEventsText(normalizedQuery),
      accountSlug: _toNullableEventsText(accountSlug),
    );
  }

  void _scheduleRelatedAccountProfileSearchReload({
    required bool immediate,
  }) {
    _relatedAccountProfileSearchDebounce?.cancel();
    final nextRequestToken = _relatedAccountProfileSearchRequestToken + 1;
    _relatedAccountProfileSearchRequestToken = nextRequestToken;
    if (immediate) {
      unawaited(
        _loadRelatedAccountProfileSearchPage(
          isInitial: true,
          requestToken: nextRequestToken,
        ),
      );
      return;
    }
    _relatedAccountProfileSearchDebounce = Timer(
      _relatedAccountProfileSearchDebounceDuration,
      () {
        unawaited(
          _loadRelatedAccountProfileSearchPage(
            isInitial: true,
            requestToken: nextRequestToken,
          ),
        );
      },
    );
  }

  Future<void> _reloadRelatedAccountProfileSearch({
    required bool immediate,
  }) async {
    _scheduleRelatedAccountProfileSearchReload(immediate: immediate);
    if (!immediate) {
      return;
    }

    while (_isFetchingRelatedAccountProfileSearchPage ||
        relatedAccountProfileSearchLoadingStreamValue.value) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> _loadRelatedAccountProfileSearchPage({
    required bool isInitial,
    required int requestToken,
  }) async {
    if (_isFetchingRelatedAccountProfileSearchPage) {
      if (isInitial) {
        _hasPendingRelatedAccountProfileSearchReload = true;
      }
      return;
    }
    if (!isInitial && !relatedAccountProfileSearchHasMoreStreamValue.value) {
      return;
    }

    _isFetchingRelatedAccountProfileSearchPage = true;
    if (isInitial) {
      relatedAccountProfileSearchLoadingStreamValue.addValue(true);
      relatedAccountProfileSearchErrorStreamValue.addValue('');
    } else {
      relatedAccountProfileSearchPageLoadingStreamValue.addValue(true);
    }

    try {
      final query = relatedAccountProfileSearchQueryStreamValue.value.trim();
      final pageResult = await _loadRelatedAccountProfileCandidates(
        accountSlug: _relatedAccountProfileSearchAccountSlug,
        isInitial: isInitial,
        query: query,
      );

      if (_isDisposed ||
          requestToken != _relatedAccountProfileSearchRequestToken) {
        return;
      }

      final nextItems = isInitial
          ? pageResult.items
          : _mergeAccountProfiles(
              relatedAccountProfileSearchResultsStreamValue.value,
              pageResult.items,
            );

      _relatedAccountProfileSearchCurrentPage =
          isInitial ? 1 : _relatedAccountProfileSearchCurrentPage + 1;
      relatedAccountProfileSearchResultsStreamValue
          .addValue(List.unmodifiable(nextItems));
      relatedAccountProfileSearchHasMoreStreamValue
          .addValue(pageResult.hasMore);
      relatedAccountProfileSearchErrorStreamValue.addValue('');
      _mergeKnownRelatedAccountProfiles(pageResult.items);
    } catch (error) {
      if (_isDisposed ||
          requestToken != _relatedAccountProfileSearchRequestToken) {
        return;
      }
      if (isInitial) {
        relatedAccountProfileSearchResultsStreamValue.addValue(const []);
        relatedAccountProfileSearchHasMoreStreamValue.addValue(false);
      }
      relatedAccountProfileSearchErrorStreamValue.addValue(error.toString());
    } finally {
      _isFetchingRelatedAccountProfileSearchPage = false;
      if (!_isDisposed &&
          requestToken == _relatedAccountProfileSearchRequestToken) {
        if (isInitial) {
          relatedAccountProfileSearchLoadingStreamValue.addValue(false);
        } else {
          relatedAccountProfileSearchPageLoadingStreamValue.addValue(false);
        }
      }

      if (_hasPendingRelatedAccountProfileSearchReload) {
        _hasPendingRelatedAccountProfileSearchReload = false;
        unawaited(
          _loadRelatedAccountProfileSearchPage(
            isInitial: true,
            requestToken: _relatedAccountProfileSearchRequestToken,
          ),
        );
      }
    }
  }

  void _bindRelatedAccountProfileSearchScroll() {
    relatedAccountProfileSearchScrollController.addListener(() {
      if (_isDisposed ||
          !relatedAccountProfileSearchScrollController.hasClients) {
        return;
      }
      final position = relatedAccountProfileSearchScrollController.position;
      if (position.pixels < position.maxScrollExtent - 160) {
        return;
      }
      unawaited(loadNextRelatedAccountProfileSearchPage());
    });
  }

  void _mergeKnownRelatedAccountProfiles(
    Iterable<TenantAdminAccountProfile> profiles,
  ) {
    if (profiles.isEmpty) {
      return;
    }
    relatedAccountProfileCandidatesStreamValue.addValue(
      List.unmodifiable(
        _mergeAccountProfiles(
          relatedAccountProfileCandidatesStreamValue.value,
          profiles,
        ),
      ),
    );
  }

  List<TenantAdminAccountProfile> _mergeAccountProfiles(
    Iterable<TenantAdminAccountProfile> current,
    Iterable<TenantAdminAccountProfile> incoming,
  ) {
    final orderedIds = <String>[
      for (final profile in current) profile.id,
    ];
    final byId = <String, TenantAdminAccountProfile>{
      for (final profile in current) profile.id: profile,
    };

    for (final profile in incoming) {
      if (!byId.containsKey(profile.id)) {
        orderedIds.add(profile.id);
      }
      byId[profile.id] = profile;
    }

    return orderedIds.map((id) => byId[id]!).toList(growable: false);
  }

  Future<TenantAdminEvent?> submitCreate(
    TenantAdminEventDraft draft, {
    String? accountSlug,
  }) async {
    if (_submitInFlight || submitLoadingStreamValue.value == true) {
      return null;
    }
    _submitInFlight = true;
    submitLoadingStreamValue.addValue(true);
    submitErrorMessageStreamValue.addValue(null);
    submitSuccessMessageStreamValue.addValue(null);
    try {
      final normalizedAccountSlug = accountSlug?.trim();
      final isAccountScoped =
          normalizedAccountSlug != null && normalizedAccountSlug.isNotEmpty;
      final created = isAccountScoped
          ? await _eventsRepository.createOwnEvent(
              accountSlug: _toEventsText(normalizedAccountSlug),
              draft: draft,
            )
          : await _eventsRepository.createEvent(draft: draft);
      if (_isDisposed) {
        return null;
      }
      submitSuccessMessageStreamValue.addValue('Evento criado com sucesso.');
      if (!isAccountScoped) {
        await loadEvents();
      }
      return created;
    } catch (error) {
      if (_isDisposed) {
        return null;
      }
      submitErrorMessageStreamValue.addValue(error.toString());
      return null;
    } finally {
      _submitInFlight = false;
      if (!_isDisposed) {
        submitLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<TenantAdminEvent?> submitUpdate({
    required String eventId,
    required TenantAdminEventDraft draft,
  }) async {
    if (_submitInFlight || submitLoadingStreamValue.value == true) {
      return null;
    }
    _submitInFlight = true;
    submitLoadingStreamValue.addValue(true);
    submitErrorMessageStreamValue.addValue(null);
    submitSuccessMessageStreamValue.addValue(null);
    try {
      final updated = await _eventsRepository.updateEvent(
        eventId: _toEventsText(eventId),
        draft: draft,
      );
      if (_isDisposed) {
        return null;
      }
      submitSuccessMessageStreamValue
          .addValue('Evento atualizado com sucesso.');
      await loadEvents();
      eventDetailStreamValue.addValue(updated);
      return updated;
    } catch (error) {
      if (_isDisposed) {
        return null;
      }
      submitErrorMessageStreamValue.addValue(error.toString());
      return null;
    } finally {
      _submitInFlight = false;
      if (!_isDisposed) {
        submitLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsRepository.deleteEvent(_toEventsText(eventId));
      if (_isDisposed) {
        return;
      }
      await loadEvents();
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      eventsErrorStreamValue.addValue(error.toString());
      rethrow;
    }
  }

  Future<TenantAdminLegacyEventPartiesSummary>
      inspectLegacyEventParties() async {
    return _eventsRepository.fetchLegacyEventPartiesSummary();
  }

  Future<TenantAdminLegacyEventPartiesSummary>
      repairLegacyEventParties() async {
    final summary = await _eventsRepository.repairLegacyEventParties();
    await loadEvents();
    return summary;
  }

  void clearSubmitMessages() {
    submitErrorMessageStreamValue.addValue(null);
    submitSuccessMessageStreamValue.addValue(null);
  }

  void _resetTenantScopedState() {
    _submitInFlight = false;
    _relatedAccountProfileSearchDebounce?.cancel();
    _relatedAccountProfileSearchAccountSlug = null;
    _relatedAccountProfileSearchCurrentPage = 0;
    _relatedAccountProfileSearchRequestToken = 0;
    _isFetchingRelatedAccountProfileSearchPage = false;
    _hasPendingRelatedAccountProfileSearchReload = false;
    _eventsRepository.resetEventsState();
    statusFilterStreamValue.addValue(null);
    archivedFilterStreamValue.addValue(false);
    temporalFilterStreamValue
        .addValue(TenantAdminEventTemporalBucket.defaultSelection);
    eventDetailStreamValue.addValue(null);
    eventDetailLoadingStreamValue.addValue(false);
    eventDetailErrorStreamValue.addValue(null);
    taxonomiesStreamValue.addValue(const []);
    taxonomyTermsBySlugStreamValue.addValue(const {});
    taxonomyLoadingStreamValue.addValue(false);
    taxonomyErrorStreamValue.addValue(null);
    eventTypeCatalogStreamValue.addValue(const []);
    venueCandidatesStreamValue.addValue(const []);
    relatedAccountProfileCandidatesStreamValue.addValue(const []);
    relatedAccountProfileSearchResultsStreamValue.addValue(const []);
    relatedAccountProfileSearchLoadingStreamValue.addValue(false);
    relatedAccountProfileSearchPageLoadingStreamValue.addValue(false);
    relatedAccountProfileSearchHasMoreStreamValue.addValue(true);
    relatedAccountProfileSearchErrorStreamValue.addValue('');
    relatedAccountProfileSearchQueryStreamValue.addValue('');
    relatedAccountProfileSearchController.clear();
    accountProfileCandidatesLoadingStreamValue.addValue(false);
    accountProfileCandidatesErrorStreamValue.addValue(null);
    eventCoverFileStreamValue.addValue(null);
    eventCoverBusyStreamValue.addValue(false);
    eventCoverRemoveStreamValue.addValue(false);
    clearSubmitMessages();
  }

  void _replaceEventFormState(TenantAdminEventFormState nextState) {
    eventFormStateStreamValue.addValue(nextState);
  }

  void _syncEventDateTimeControllers(TenantAdminEventFormState state) {
    eventStartController.text = _formatDateTime(state.startAt);
    eventEndController.text = _formatDateTime(state.endAt);
    eventPublishAtController.text = _formatDateTime(state.publishAt);
  }

  void _syncEventTypeSlugFromName() {
    final state = eventTypeFormStateStreamValue.value;
    if (!state.isSlugAutoEnabled || state.isEdit) {
      return;
    }
    final generated = _tenantAdminSlugify(eventTypeNameController.text);
    if (eventTypeSlugController.text == generated) {
      return;
    }
    eventTypeSlugController.value = eventTypeSlugController.value.copyWith(
      text: generated,
      selection: TextSelection.collapsed(offset: generated.length),
      composing: TextRange.empty,
    );
  }

  TenantAdminPoiVisualMode get currentEventTypePoiVisualMode =>
      eventTypePoiVisualModeStreamValue.value;

  TenantAdminPoiVisualImageSource get currentEventTypePoiVisualImageSource =>
      eventTypePoiVisualImageSourceStreamValue.value;

  void updateEventTypePoiVisualMode(TenantAdminPoiVisualMode mode) {
    eventTypePoiVisualModeStreamValue.addValue(mode);
    if (mode == TenantAdminPoiVisualMode.image &&
        currentEventTypePoiVisualImageSource ==
            TenantAdminPoiVisualImageSource.avatar) {
      eventTypePoiVisualImageSourceStreamValue.addValue(
        TenantAdminPoiVisualImageSource.cover,
      );
    }
  }

  void updateEventTypePoiVisualImageSource(
    TenantAdminPoiVisualImageSource source,
  ) {
    if (source == TenantAdminPoiVisualImageSource.avatar) {
      return;
    }
    eventTypePoiVisualImageSourceStreamValue.addValue(source);
    if (source != TenantAdminPoiVisualImageSource.typeAsset) {
      eventTypeRemoveTypeAssetStreamValue.addValue(false);
    }
  }

  TenantAdminPoiVisual? buildCurrentEventTypeVisual() {
    if (currentEventTypePoiVisualMode == TenantAdminPoiVisualMode.icon) {
      try {
        final iconValue = TenantAdminRequiredTextValue()
          ..parse(eventTypePoiVisualIconController.text);
        final colorValue = TenantAdminHexColorValue()
          ..parse(eventTypePoiVisualColorController.text);
        final iconColorValue = TenantAdminHexColorValue()
          ..parse(eventTypePoiVisualIconColorController.text);
        final candidate = TenantAdminPoiVisual.icon(
          iconValue: iconValue,
          colorValue: colorValue,
          iconColorValue: iconColorValue,
        );
        return candidate.isValid ? candidate : null;
      } on Object {
        return null;
      }
    }

    return TenantAdminPoiVisual.image(
      imageSource: currentEventTypePoiVisualImageSource,
      imageUrlValue: currentEventTypePoiVisualImageSource ==
              TenantAdminPoiVisualImageSource.typeAsset
          ? _buildOptionalUrlValue(currentEventTypeTypeAssetUrl)
          : null,
    );
  }

  XFile? get currentEventTypeTypeAssetFile =>
      eventTypeTypeAssetFileStreamValue.value;

  String? get currentEventTypeTypeAssetUrl {
    if (eventTypeRemoveTypeAssetStreamValue.value) {
      return null;
    }
    return _normalizeOptionalText(eventTypeTypeAssetUrlStreamValue.value);
  }

  bool get isEventTypeTypeAssetMarkedForRemoval =>
      eventTypeRemoveTypeAssetStreamValue.value;

  Future<XFile?> pickEventTypeAssetImageFromDevice() {
    return _imageIngestionService.pickFromDevice(
      slot: TenantAdminImageSlot.typeVisual,
    );
  }

  Future<XFile> fetchEventTypeImageFromUrlForCrop({
    required String imageUrl,
  }) {
    return _imageIngestionService.fetchFromUrlForCrop(imageUrl: imageUrl);
  }

  Future<Uint8List> readEventTypeImageBytesForCrop(XFile sourceFile) {
    return _imageIngestionService.readBytesForCrop(sourceFile);
  }

  Future<XFile> prepareEventTypeCroppedImage(
    Uint8List croppedData, {
    required TenantAdminImageSlot slot,
  }) {
    return _imageIngestionService.prepareBytesAsXFile(
      croppedData,
      slot: slot,
      applyAspectCrop: false,
    );
  }

  Future<TenantAdminMediaUpload?> buildEventTypeAssetUpload() {
    return _imageIngestionService.buildUpload(
      currentEventTypeTypeAssetFile,
      slot: TenantAdminImageSlot.typeVisual,
    );
  }

  void updateEventTypeTypeAssetFile(XFile? file) {
    eventTypeTypeAssetFileStreamValue.addValue(file);
    if (file != null) {
      eventTypeRemoveTypeAssetStreamValue.addValue(false);
    }
  }

  void clearEventTypeTypeAssetSelection() {
    if (currentEventTypeTypeAssetFile != null) {
      eventTypeTypeAssetFileStreamValue.addValue(null);
      return;
    }

    final hasExistingTypeAsset = currentEventTypeTypeAssetUrl != null;
    if (!hasExistingTypeAsset) {
      eventTypeRemoveTypeAssetStreamValue.addValue(false);
      return;
    }

    eventTypeRemoveTypeAssetStreamValue.addValue(
      !eventTypeRemoveTypeAssetStreamValue.value,
    );
  }

  void _syncEventTypeVisualForm(TenantAdminPoiVisual? visual) {
    eventTypeTypeAssetFileStreamValue.addValue(null);
    eventTypeRemoveTypeAssetStreamValue.addValue(false);
    if (visual == null || visual.mode == TenantAdminPoiVisualMode.icon) {
      eventTypePoiVisualModeStreamValue.addValue(TenantAdminPoiVisualMode.icon);
      eventTypePoiVisualIconController.text = visual?.icon ?? 'place';
      eventTypePoiVisualColorController.text = visual?.color ?? '#2563EB';
      eventTypePoiVisualIconColorController.text =
          visual?.iconColor ?? '#FFFFFF';
      eventTypePoiVisualImageSourceStreamValue.addValue(
        TenantAdminPoiVisualImageSource.cover,
      );
      eventTypeTypeAssetUrlStreamValue.addValue('');
      return;
    }

    eventTypePoiVisualModeStreamValue.addValue(TenantAdminPoiVisualMode.image);
    eventTypePoiVisualIconController.text = 'place';
    eventTypePoiVisualColorController.text = '#2563EB';
    eventTypePoiVisualIconColorController.text = '#FFFFFF';
    final imageSource =
        visual.imageSource == TenantAdminPoiVisualImageSource.avatar
            ? TenantAdminPoiVisualImageSource.cover
            : (visual.imageSource ?? TenantAdminPoiVisualImageSource.cover);
    eventTypePoiVisualImageSourceStreamValue.addValue(imageSource);
    eventTypeTypeAssetUrlStreamValue.addValue(visual.imageUrl ?? '');
  }

  String _tenantAdminSlugify(String rawValue) {
    final lower = rawValue.trim().toLowerCase();
    if (lower.isEmpty) {
      return '';
    }
    final builder = StringBuffer();
    var previousWasHyphen = false;
    for (final codeUnit in lower.codeUnits) {
      final isAlphaNumeric = (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 97 && codeUnit <= 122);
      if (isAlphaNumeric) {
        builder.writeCharCode(codeUnit);
        previousWasHyphen = false;
        continue;
      }
      final isAllowedSeparator = codeUnit == 45 || codeUnit == 95;
      if (!isAllowedSeparator) {
        if (!previousWasHyphen && builder.length > 0) {
          builder.write('-');
          previousWasHyphen = true;
        }
        continue;
      }
      if (builder.isEmpty || previousWasHyphen) {
        continue;
      }
      builder.writeCharCode(codeUnit);
      previousWasHyphen = true;
    }
    final normalized = builder.toString();
    return normalized.replaceAll(RegExp(r'[-_]+$'), '');
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    final local = TimezoneConverter.utcToLocal(dateTime);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  String? _normalizeTenantDomain(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
  }

  bool _hasLandlordToken() {
    if (_landlordAuthRepository == null) {
      return true;
    }
    final token = _landlordAuthRepository.token.trim();
    return token.isNotEmpty;
  }

  void dispose() {
    _isDisposed = true;
    _relatedAccountProfileSearchDebounce?.cancel();
    unawaited(_tenantScopeSubscription?.cancel());
    unawaited(_hasMoreEventsSubscription?.cancel());
    unawaited(_isEventsPageLoadingSubscription?.cancel());
    unawaited(_eventsErrorSubscription?.cancel());
    if (_eventTypeNameSyncListener != null) {
      eventTypeNameController.removeListener(_eventTypeNameSyncListener!);
      _eventTypeNameSyncListener = null;
    }
    hasMoreEventsStreamValue.dispose();
    isEventsPageLoadingStreamValue.dispose();
    eventsErrorStreamValue.dispose();
    statusFilterStreamValue.dispose();
    archivedFilterStreamValue.dispose();
    temporalFilterStreamValue.dispose();
    eventDetailStreamValue.dispose();
    eventDetailLoadingStreamValue.dispose();
    eventDetailErrorStreamValue.dispose();
    submitLoadingStreamValue.dispose();
    submitErrorMessageStreamValue.dispose();
    submitSuccessMessageStreamValue.dispose();
    eventTypeCatalogStreamValue.dispose();
    taxonomiesStreamValue.dispose();
    taxonomyTermsBySlugStreamValue.dispose();
    taxonomyLoadingStreamValue.dispose();
    taxonomyErrorStreamValue.dispose();
    venueCandidatesStreamValue.dispose();
    relatedAccountProfileCandidatesStreamValue.dispose();
    relatedAccountProfileSearchResultsStreamValue.dispose();
    relatedAccountProfileSearchLoadingStreamValue.dispose();
    relatedAccountProfileSearchPageLoadingStreamValue.dispose();
    relatedAccountProfileSearchHasMoreStreamValue.dispose();
    relatedAccountProfileSearchErrorStreamValue.dispose();
    relatedAccountProfileSearchQueryStreamValue.dispose();
    accountProfileCandidatesLoadingStreamValue.dispose();
    accountProfileCandidatesErrorStreamValue.dispose();
    eventsScrollController.dispose();
    relatedAccountProfileSearchScrollController.dispose();
    eventFormStateStreamValue.dispose();
    relatedAccountProfileSearchController.dispose();
    eventTitleController.dispose();
    eventContentController.dispose();
    eventStartController.dispose();
    eventEndController.dispose();
    eventPublishAtController.dispose();
    eventOnlineUrlController.dispose();
    eventOnlinePlatformController.dispose();
    eventCoverFileStreamValue.dispose();
    eventCoverBusyStreamValue.dispose();
    eventCoverRemoveStreamValue.dispose();
    eventTypeFormStateStreamValue.dispose();
    eventTypeNameController.dispose();
    eventTypeSlugController.dispose();
    eventTypeDescriptionController.dispose();
    eventTypePoiVisualModeStreamValue.dispose();
    eventTypePoiVisualImageSourceStreamValue.dispose();
    eventTypePoiVisualIconController.dispose();
    eventTypePoiVisualColorController.dispose();
    eventTypePoiVisualIconColorController.dispose();
    eventTypeTypeAssetFileStreamValue.dispose();
    eventTypeTypeAssetUrlStreamValue.dispose();
    eventTypeRemoveTypeAssetStreamValue.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}

extension _TenantAdminIterableFirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
