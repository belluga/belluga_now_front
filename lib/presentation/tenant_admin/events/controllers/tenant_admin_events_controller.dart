import 'dart:async';

import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantAdminEventsController implements Disposable {
  TenantAdminEventsController({
    TenantAdminEventsRepositoryContract? eventsRepository,
    TenantAdminTaxonomiesRepositoryContract? taxonomiesRepository,
    TenantAdminTenantScopeContract? tenantScope,
    LandlordAuthRepositoryContract? landlordAuthRepository,
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
                : null) {
    _bindTenantScope();
  }

  final TenantAdminEventsRepositoryContract _eventsRepository;
  final TenantAdminTaxonomiesRepositoryContract _taxonomiesRepository;
  final TenantAdminTenantScopeContract? _tenantScope;
  final LandlordAuthRepositoryContract? _landlordAuthRepository;

  static const int _eventsPageSize = 20;

  StreamValue<List<TenantAdminEvent>?> get eventsStreamValue =>
      _eventsRepository.eventsStreamValue;
  StreamValue<bool> get hasMoreEventsStreamValue =>
      _eventsRepository.hasMoreEventsStreamValue;
  StreamValue<bool> get isEventsPageLoadingStreamValue =>
      _eventsRepository.isEventsPageLoadingStreamValue;
  StreamValue<String?> get eventsErrorStreamValue =>
      _eventsRepository.eventsErrorStreamValue;

  final StreamValue<String?> statusFilterStreamValue =
      StreamValue<String?>(defaultValue: null);
  final StreamValue<bool> archivedFilterStreamValue =
      StreamValue<bool>(defaultValue: false);

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
      artistCandidatesStreamValue =
      StreamValue<List<TenantAdminAccountProfile>>(defaultValue: const []);
  final StreamValue<bool> partyCandidatesLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<String?> partyCandidatesErrorStreamValue =
      StreamValue<String?>();

  final ScrollController eventsScrollController = ScrollController();

  final GlobalKey<FormState> eventFormKey = GlobalKey<FormState>();
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

  final StreamValue<TenantAdminEventFormState> eventFormStateStreamValue =
      StreamValue<TenantAdminEventFormState>(
    defaultValue: TenantAdminEventFormState.initial(),
  );

  final GlobalKey<FormState> eventTypeFormKey = GlobalKey<FormState>();
  final TextEditingController eventTypeNameController = TextEditingController();
  final TextEditingController eventTypeSlugController = TextEditingController();
  final TextEditingController eventTypeDescriptionController =
      TextEditingController();

  final StreamValue<TenantAdminEventTypeFormState>
      eventTypeFormStateStreamValue =
      StreamValue<TenantAdminEventTypeFormState>(
    defaultValue: TenantAdminEventTypeFormState.initial(),
  );

  bool _isDisposed = false;
  StreamSubscription<String?>? _tenantScopeSubscription;
  String? _lastTenantDomain;
  VoidCallback? _eventTypeNameSyncListener;

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

  Future<void> loadEvents() async {
    if (_isDisposed) {
      return;
    }
    if (!_hasLandlordToken()) {
      _eventsRepository.resetEventsState();
      eventsStreamValue.addValue(const <TenantAdminEvent>[]);
      return;
    }
    await _eventsRepository.loadEvents(
      pageSize: _eventsPageSize,
      status: statusFilterStreamValue.value,
      archived: archivedFilterStreamValue.value,
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
      pageSize: _eventsPageSize,
      status: statusFilterStreamValue.value,
      archived: archivedFilterStreamValue.value,
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

  Future<void> applyFilters() async {
    await loadEvents();
  }

  void initEventForm({
    TenantAdminEvent? existingEvent,
  }) {
    final firstOccurrence = existingEvent?.occurrences.firstOrNull;
    final selectedTaxonomyTerms = <String, Set<String>>{};
    for (final term
        in existingEvent?.taxonomyTerms ?? const <TenantAdminTaxonomyTerm>[]) {
      final bucket =
          selectedTaxonomyTerms.putIfAbsent(term.type, () => <String>{});
      bucket.add(term.value);
    }
    final nextState = TenantAdminEventFormState(
      startAt: firstOccurrence?.dateTimeStart.toLocal(),
      endAt: firstOccurrence?.dateTimeEnd?.toLocal(),
      publishAt: existingEvent?.publication.publishAt?.toLocal(),
      locationMode: existingEvent?.location?.mode ?? 'physical',
      publicationStatus: existingEvent?.publication.status ?? 'draft',
      selectedVenueId: existingEvent?.placeRef?.id,
      selectedTypeSlug: existingEvent?.type.slug.trim(),
      selectedArtistIds: {
        ...?existingEvent?.artistIds,
      },
      selectedTaxonomyTerms: selectedTaxonomyTerms,
      hasHydratedDefaultVenue: false,
    );

    eventTitleController.text = existingEvent?.title ?? '';
    eventContentController.text = existingEvent?.content ?? '';
    eventOnlineUrlController.text = existingEvent?.location?.online?.url ?? '';
    eventOnlinePlatformController.text =
        existingEvent?.location?.online?.platform ?? '';
    _replaceEventFormState(nextState);
    _syncEventDateTimeControllers(nextState);
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

  void addEventArtist(String artistId) {
    final current = eventFormStateStreamValue.value;
    final next = {...current.selectedArtistIds, artistId};
    _replaceEventFormState(
      current.copyWith(selectedArtistIds: next),
    );
  }

  void removeEventArtist(String artistId) {
    final current = eventFormStateStreamValue.value;
    if (!current.selectedArtistIds.contains(artistId)) {
      return;
    }
    final next = {...current.selectedArtistIds}..remove(artistId);
    _replaceEventFormState(
      current.copyWith(selectedArtistIds: next),
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
    required String description,
    TenantAdminEventType? existingType,
  }) async {
    final normalizedName = name.trim();
    final normalizedSlug = slug.trim();
    final normalizedDescription = description.trim();

    final eventTypeId = existingType?.id?.trim();
    final isEdit = eventTypeId != null && eventTypeId.isNotEmpty;

    final saved = isEdit
        ? await _eventsRepository.updateEventType(
            eventTypeId: eventTypeId,
            name: normalizedName,
            slug: normalizedSlug,
            description: normalizedDescription,
          )
        : await _eventsRepository.createEventType(
            name: normalizedName,
            slug: normalizedSlug,
            description: normalizedDescription,
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

    await _eventsRepository.deleteEventType(eventTypeId);
    await _loadEventTypeCatalog();
  }

  Future<void> loadEventDetail(String eventIdOrSlug) async {
    eventDetailLoadingStreamValue.addValue(true);
    eventDetailErrorStreamValue.addValue(null);
    try {
      final event = await _eventsRepository.fetchEvent(eventIdOrSlug);
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
    final normalizedAccountSlug = accountSlug?.trim();
    final tasks = <Future<void>>[
      _loadEventTypeCatalog(),
      _loadTaxonomies(),
      _loadPartyCandidates(accountSlug: normalizedAccountSlug),
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
      final taxonomies = await _taxonomiesRepository.fetchTaxonomies();
      final filtered = taxonomies
          .where((taxonomy) => taxonomy.appliesToTarget('event'))
          .toList(growable: false);
      if (_isDisposed) {
        return;
      }
      taxonomiesStreamValue.addValue(filtered);

      final entries = await Future.wait(
        filtered.map((taxonomy) async {
          final terms = await _taxonomiesRepository.fetchTerms(
            taxonomyId: taxonomy.id,
          );
          return MapEntry<String, List<TenantAdminTaxonomyTermDefinition>>(
            taxonomy.slug,
            terms,
          );
        }),
      );

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

  Future<void> _loadPartyCandidates({
    String? accountSlug,
  }) async {
    partyCandidatesLoadingStreamValue.addValue(true);
    try {
      final candidates = await _eventsRepository.fetchPartyCandidates(
        accountSlug: accountSlug,
      );
      if (_isDisposed) {
        return;
      }
      venueCandidatesStreamValue.addValue(candidates.venues);
      artistCandidatesStreamValue.addValue(candidates.artists);
      partyCandidatesErrorStreamValue.addValue(null);
    } catch (error) {
      if (_isDisposed) {
        return;
      }
      partyCandidatesErrorStreamValue.addValue(error.toString());
    } finally {
      if (!_isDisposed) {
        partyCandidatesLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<TenantAdminEvent?> submitCreate(
    TenantAdminEventDraft draft, {
    String? accountSlug,
  }) async {
    submitLoadingStreamValue.addValue(true);
    submitErrorMessageStreamValue.addValue(null);
    submitSuccessMessageStreamValue.addValue(null);
    try {
      final normalizedAccountSlug = accountSlug?.trim();
      final isAccountScoped =
          normalizedAccountSlug != null && normalizedAccountSlug.isNotEmpty;
      final created = isAccountScoped
          ? await _eventsRepository.createOwnEvent(
              accountSlug: normalizedAccountSlug,
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
      if (!_isDisposed) {
        submitLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<TenantAdminEvent?> submitUpdate({
    required String eventId,
    required TenantAdminEventDraft draft,
  }) async {
    submitLoadingStreamValue.addValue(true);
    submitErrorMessageStreamValue.addValue(null);
    submitSuccessMessageStreamValue.addValue(null);
    try {
      final updated = await _eventsRepository.updateEvent(
        eventId: eventId,
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
      if (!_isDisposed) {
        submitLoadingStreamValue.addValue(false);
      }
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsRepository.deleteEvent(eventId);
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

  void clearSubmitMessages() {
    submitErrorMessageStreamValue.addValue(null);
    submitSuccessMessageStreamValue.addValue(null);
  }

  void _resetTenantScopedState() {
    _eventsRepository.resetEventsState();
    statusFilterStreamValue.addValue(null);
    archivedFilterStreamValue.addValue(false);
    eventDetailStreamValue.addValue(null);
    eventDetailLoadingStreamValue.addValue(false);
    eventDetailErrorStreamValue.addValue(null);
    taxonomiesStreamValue.addValue(const []);
    taxonomyTermsBySlugStreamValue.addValue(const {});
    taxonomyLoadingStreamValue.addValue(false);
    taxonomyErrorStreamValue.addValue(null);
    eventTypeCatalogStreamValue.addValue(const []);
    venueCandidatesStreamValue.addValue(const []);
    artistCandidatesStreamValue.addValue(const []);
    partyCandidatesLoadingStreamValue.addValue(false);
    partyCandidatesErrorStreamValue.addValue(null);
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
    final local = dateTime.toLocal();
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
    _tenantScopeSubscription?.cancel();
    if (_eventTypeNameSyncListener != null) {
      eventTypeNameController.removeListener(_eventTypeNameSyncListener!);
      _eventTypeNameSyncListener = null;
    }
    statusFilterStreamValue.dispose();
    archivedFilterStreamValue.dispose();
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
    artistCandidatesStreamValue.dispose();
    partyCandidatesLoadingStreamValue.dispose();
    partyCandidatesErrorStreamValue.dispose();
    eventsScrollController.dispose();
    eventFormStateStreamValue.dispose();
    eventTitleController.dispose();
    eventContentController.dispose();
    eventStartController.dispose();
    eventEndController.dispose();
    eventPublishAtController.dispose();
    eventOnlineUrlController.dispose();
    eventOnlinePlatformController.dispose();
    eventTypeFormStateStreamValue.dispose();
    eventTypeNameController.dispose();
    eventTypeSlugController.dispose();
    eventTypeDescriptionController.dispose();
  }

  @override
  void onDispose() {
    dispose();
  }
}

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
    required this.selectedArtistIds,
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
      selectedArtistIds: <String>{},
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
  final Set<String> selectedArtistIds;
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
    Set<String>? selectedArtistIds,
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
      selectedArtistIds: selectedArtistIds ?? this.selectedArtistIds,
      selectedTaxonomyTerms:
          selectedTaxonomyTerms ?? this.selectedTaxonomyTerms,
      hasHydratedDefaultVenue:
          hasHydratedDefaultVenue ?? this.hasHydratedDefaultVenue,
    );
  }
}

class TenantAdminEventTypeFormState {
  static const Object _undefined = Object();

  const TenantAdminEventTypeFormState({
    required this.isEdit,
    required this.isSlugAutoEnabled,
    required this.isSaving,
    required this.formError,
  });

  factory TenantAdminEventTypeFormState.initial() {
    return const TenantAdminEventTypeFormState(
      isEdit: false,
      isSlugAutoEnabled: true,
      isSaving: false,
      formError: null,
    );
  }

  final bool isEdit;
  final bool isSlugAutoEnabled;
  final bool isSaving;
  final String? formError;

  TenantAdminEventTypeFormState copyWith({
    bool? isEdit,
    bool? isSlugAutoEnabled,
    bool? isSaving,
    Object? formError = _undefined,
  }) {
    return TenantAdminEventTypeFormState(
      isEdit: isEdit ?? this.isEdit,
      isSlugAutoEnabled: isSlugAutoEnabled ?? this.isSlugAutoEnabled,
      isSaving: isSaving ?? this.isSaving,
      formError:
          formError == _undefined ? this.formError : formError as String?,
    );
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
