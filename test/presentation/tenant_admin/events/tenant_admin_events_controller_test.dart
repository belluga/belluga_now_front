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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_profile_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_by_taxonomy_id.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test(
    'deleteEvent rethrows repository errors and updates error stream',
    () async {
      final eventsRepository = _FailingDeleteEventsRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      await expectLater(
        () => controller.deleteEvent('evt-1'),
        throwsA(isA<StateError>()),
      );

      final error = controller.eventsErrorStreamValue.value;
      expect(error, isNotNull);
      expect(error, contains('delete failed'));
    },
  );

  test('loadEvents forwards default temporal filters to repository', () async {
    final eventsRepository = _TrackingEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
        'landlord-token',
      ),
    );

    await controller.loadEvents();

    expect(
      eventsRepository.lastTemporalBuckets,
      equals(TenantAdminEventTemporalBucket.defaultSelection),
    );
  });

  test(
    'loadEvents forwards specific date, venue, and related profile filters',
    () async {
      final eventsRepository = _TrackingEventsRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      controller.selectSpecificDateFilter(DateTime(2026, 4, 12));
      controller.selectVenueFilter(
        tenantAdminAccountProfileFromRaw(
          id: 'venue-1',
          accountId: 'acc-venue-1',
          profileType: 'venue',
          displayName: 'Main Venue',
        ),
      );
      controller.selectRelatedAccountProfileFilter(
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-profile-1',
          profileType: 'artist',
          displayName: 'DJ Test',
        ),
      );

      await controller.loadEvents();

      expect(eventsRepository.lastLoadSpecificDate, '2026-04-12');
      expect(eventsRepository.lastLoadVenueProfileId, 'venue-1');
      expect(eventsRepository.lastLoadRelatedAccountProfileId, 'profile-1');
    },
  );

  test(
    'loadEvents records repository errors when a filtered reload fails',
    () async {
      final eventsRepository = _FailingFilteredLoadEventsRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      controller.selectSpecificDateFilter(DateTime(2026, 4, 12));

      await controller.loadEvents();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(eventsRepository.lastLoadSpecificDate, '2026-04-12');
      expect(controller.eventsStreamValue.value, isEmpty);
      expect(
        controller.eventsErrorStreamValue.value,
        contains('filtered load failed'),
      );
    },
  );

  test(
    'root programming stays on the first occurrence after a second occurrence is drafted and populated',
    () {
      final eventsRepository = _TrackingEventsRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      controller.initEventForm(
        existingEvent: _buildEventDetailFixture(
          eventId: 'evt-programming-scope',
          title: 'Programming Scope Event',
        ),
      );

      final primaryKey = controller.primaryOccurrenceKey();
      expect(primaryKey, isNotNull);

      controller.addOccurrenceProgrammingItem(
        primaryKey!,
        TenantAdminEventProgrammingItem(
          timeValue: tenantAdminOptionalText('09:30'),
          titleValue: tenantAdminOptionalText('Programação raiz'),
        ),
      );

      final secondOccurrenceKey = controller.createOccurrenceDraft();
      controller.addOccurrenceProgrammingItem(
        secondOccurrenceKey,
        TenantAdminEventProgrammingItem(
          timeValue: tenantAdminOptionalText('13:00'),
          titleValue: tenantAdminOptionalText('Programação local'),
        ),
      );

      final occurrences =
          controller.eventFormStateStreamValue.value.occurrences;
      expect(occurrences, hasLength(2));
      expect(
        occurrences.first.programmingItems.map((item) => item.title).toList(),
        ['Programação raiz'],
      );
      expect(
        occurrences.last.programmingItems.map((item) => item.title).toList(),
        ['Programação local'],
      );
    },
  );

  test(
    'initEventForm preserves hydrated occurrence order when assigning the primary draft',
    () {
      final eventsRepository = _TrackingEventsRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      controller.initEventForm(
        existingEvent: TenantAdminEvent(
          eventIdValue: tenantAdminRequiredText('evt-programming-order'),
          slugValue: tenantAdminRequiredText('evt-programming-order'),
          titleValue: tenantAdminRequiredText('Programming Order Event'),
          contentValue: tenantAdminOptionalText(''),
          type: TenantAdminEventType(
            nameValue: tenantAdminRequiredText('Show'),
            slugValue: tenantAdminRequiredText('show'),
          ),
          occurrences: <TenantAdminEventOccurrence>[
            TenantAdminEventOccurrence(
              occurrenceIdValue: tenantAdminOptionalText('occ-2'),
              occurrenceSlugValue: tenantAdminOptionalText('occ-2'),
              dateTimeStartValue: tenantAdminDateTime(
                DateTime.utc(2026, 4, 21, 20),
              ),
              programmingItems: [
                TenantAdminEventProgrammingItem(
                  timeValue: tenantAdminOptionalText('13:00'),
                  titleValue: tenantAdminOptionalText('Programação local'),
                ),
              ],
            ),
            TenantAdminEventOccurrence(
              occurrenceIdValue: tenantAdminOptionalText('occ-1'),
              occurrenceSlugValue: tenantAdminOptionalText('occ-1'),
              dateTimeStartValue: tenantAdminDateTime(
                DateTime.utc(2026, 4, 20, 20),
              ),
              programmingItems: [
                TenantAdminEventProgrammingItem(
                  timeValue: tenantAdminOptionalText('09:30'),
                  titleValue: tenantAdminOptionalText('Programação raiz'),
                ),
              ],
            ),
          ],
          publication: TenantAdminEventPublication(
            statusValue: tenantAdminRequiredText('draft'),
          ),
        ),
      );

      final occurrences =
          controller.eventFormStateStreamValue.value.occurrences;
      expect(
        occurrences.map((occurrence) => occurrence.occurrenceId).toList(),
        ['occ-2', 'occ-1'],
      );
      expect(
        occurrences.first.programmingItems.map((item) => item.title).toList(),
        ['Programação local'],
      );
      expect(
        occurrences.last.programmingItems.map((item) => item.title).toList(),
        ['Programação raiz'],
      );
      expect(
        controller.eventFormStateStreamValue.value.startAt,
        TimezoneConverter.utcToLocal(DateTime.utc(2026, 4, 21, 20)),
      );
    },
  );

  test('clearEventEndAt clears the optional first occurrence end date', () {
    final controller = TenantAdminEventsController(
      eventsRepository: _TrackingEventsRepository(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
        'landlord-token',
      ),
    );
    final startAt = DateTime(2026, 4, 22, 10);
    final endAt = DateTime(2026, 4, 22, 12);

    controller.applyEventStartAt(startAt);
    controller.applyEventEndAt(endAt);

    expect(controller.eventFormStateStreamValue.value.endAt, endAt);
    expect(
      controller.eventFormStateStreamValue.value.occurrences.first.dateTimeEnd,
      endAt,
    );

    controller.clearEventEndAt();

    expect(controller.eventFormStateStreamValue.value.endAt, isNull);
    expect(controller.eventEndController.text, isEmpty);
    expect(
      controller.eventFormStateStreamValue.value.occurrences.first.dateTimeEnd,
      isNull,
    );
  });

  test(
    'related account profile selection preserves order and supports reorder',
    () {
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      controller.initEventForm();
      controller.addRelatedAccountProfile('artist-1');
      controller.addRelatedAccountProfile('producer-1');
      controller.addRelatedAccountProfile('band-1');

      controller.reorderRelatedAccountProfile(profileId: 'band-1', newIndex: 1);

      expect(
        controller
            .eventFormStateStreamValue
            .value
            .selectedRelatedAccountProfileIds,
        ['artist-1', 'band-1', 'producer-1'],
      );

      controller.removeRelatedAccountProfile('band-1');

      expect(
        controller
            .eventFormStateStreamValue
            .value
            .selectedRelatedAccountProfileIds,
        ['artist-1', 'producer-1'],
      );
    },
  );

  test(
    'initEventForm seeds related profile cache with occurrence-owned profiles',
    () {
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );
      final occurrenceArtist = tenantAdminAccountProfileFromRaw(
        id: 'occ-artist-1',
        accountId: 'acc-occ-artist-1',
        profileType: 'artist',
        displayName: 'Occurrence Artist',
      );
      final occurrenceExhibitor = tenantAdminAccountProfileFromRaw(
        id: 'occ-exhibitor-1',
        accountId: 'acc-occ-exhibitor-1',
        profileType: 'exhibitor',
        displayName: 'Occurrence Exhibitor',
      );
      final existingEvent = TenantAdminEvent(
        eventIdValue: tenantAdminRequiredText('evt-occ-cache'),
        slugValue: tenantAdminRequiredText('evt-occ-cache'),
        titleValue: tenantAdminRequiredText('Evento em edição'),
        contentValue: tenantAdminOptionalText('Conteúdo'),
        type: TenantAdminEventType(
          idValue: tenantAdminOptionalText('type-1'),
          nameValue: tenantAdminRequiredText('Show'),
          slugValue: tenantAdminRequiredText('show'),
        ),
        occurrences: <TenantAdminEventOccurrence>[
          TenantAdminEventOccurrence(
            dateTimeStartValue: tenantAdminDateTime(
              DateTime.utc(2026, 6, 7, 3),
            ),
          ),
          TenantAdminEventOccurrence(
            occurrenceIdValue: tenantAdminOptionalText('occurrence-2'),
            dateTimeStartValue: tenantAdminDateTime(
              DateTime.utc(2026, 6, 8, 3),
            ),
            relatedAccountProfileIdValues: [
              TenantAdminAccountProfileIdValue(occurrenceArtist.id),
              TenantAdminAccountProfileIdValue(occurrenceExhibitor.id),
            ],
            relatedAccountProfiles: [occurrenceArtist, occurrenceExhibitor],
            profileGroups: [
              TenantAdminNestedProfileGroup(
                idValue: TenantAdminNestedProfileGroupTextValue('outro-grupo'),
                labelValue: TenantAdminNestedProfileGroupTextValue(
                  'Outro Grupo',
                ),
                orderValue: TenantAdminNestedProfileGroupOrderValue(0),
                accountProfileIdValues: [
                  TenantAdminNestedProfileGroupTextValue(occurrenceArtist.id),
                  TenantAdminNestedProfileGroupTextValue(
                    occurrenceExhibitor.id,
                  ),
                ],
              ),
            ],
          ),
        ],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText('draft'),
        ),
      );

      controller.initEventForm(existingEvent: existingEvent);

      expect(
        controller.relatedAccountProfileCandidatesStreamValue.value.map(
          (profile) => profile.id,
        ),
        containsAll([occurrenceArtist.id, occurrenceExhibitor.id]),
      );
    },
  );

  test(
    'upsertOccurrence keeps occurrence programming profiles out of event-level related selection',
    () {
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );
      final occurrenceProfile = tenantAdminAccountProfileFromRaw(
        id: 'artist-1',
        accountId: 'acc-artist-1',
        profileType: 'artist',
        displayName: 'Artist A',
      );

      controller.initEventForm();
      controller.addRelatedAccountProfile('producer-1');
      controller.upsertOccurrence(
        index: null,
        occurrence: TenantAdminEventOccurrence(
          dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 22, 20)),
          relatedAccountProfileIdValues:
              List<TenantAdminAccountProfileIdValue>.of([
                TenantAdminAccountProfileIdValue('artist-1'),
              ]),
          relatedAccountProfiles: [occurrenceProfile],
            programmingItems: List<TenantAdminEventProgrammingItem>.of([
            TenantAdminEventProgrammingItem(
              timeValue: tenantAdminOptionalText('20:00'),
              accountProfileIdValues: List<TenantAdminAccountProfileIdValue>.of(
                [TenantAdminAccountProfileIdValue('artist-1')],
              ),
              linkedAccountProfiles: [occurrenceProfile],
            ),
          ]),
        ),
      );

      expect(
        controller
            .eventFormStateStreamValue
            .value
            .selectedRelatedAccountProfileIds,
        ['producer-1'],
      );
      expect(
        controller
            .eventFormStateStreamValue
            .value
            .occurrences
            .single
            .relatedAccountProfileIds
            .map((value) => value.value)
            .toList(growable: false),
        ['artist-1'],
      );
      expect(
        controller
            .eventFormStateStreamValue
            .value
            .occurrences
            .single
            .programmingItems
            .single
            .accountProfileIds
            .map((value) => value.value)
            .toList(growable: false),
        ['artist-1'],
      );
    },
  );

  test(
    'occurrence profile-group changes clear stale programming profile links for removed members',
    () {
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );
      final occurrenceProfile = tenantAdminAccountProfileFromRaw(
        id: 'artist-1',
        accountId: 'acc-artist-1',
        profileType: 'artist',
        displayName: 'Artist A',
      );

      controller.initEventForm();
      controller.upsertOccurrence(
        index: null,
        occurrence: TenantAdminEventOccurrence(
          dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 4, 22, 20)),
          relatedAccountProfileIdValues:
              List<TenantAdminAccountProfileIdValue>.of([
                TenantAdminAccountProfileIdValue('artist-1'),
              ]),
          relatedAccountProfiles: [occurrenceProfile],
          profileGroups: [
            TenantAdminNestedProfileGroup(
              idValue: TenantAdminNestedProfileGroupTextValue('bandas'),
              labelValue: TenantAdminNestedProfileGroupTextValue('Bandas'),
              orderValue: TenantAdminNestedProfileGroupOrderValue(0),
              accountProfileIdValues: [
                TenantAdminNestedProfileGroupTextValue('artist-1'),
              ],
            ),
          ],
          programmingItems: List<TenantAdminEventProgrammingItem>.of([
            TenantAdminEventProgrammingItem(
              timeValue: tenantAdminOptionalText('20:00'),
              titleValue: tenantAdminOptionalText('Show principal'),
              accountProfileIdValues: List<TenantAdminAccountProfileIdValue>.of(
                [TenantAdminAccountProfileIdValue('artist-1')],
              ),
              linkedAccountProfiles: [occurrenceProfile],
            ),
          ]),
        ),
      );

      controller.toggleOccurrenceProfileGroupMember(
        occurrenceKey: (controller.primaryOccurrenceKey())!,
        groupId: 'bandas',
        profileId: 'artist-1',
        selected: false,
      );

      final occurrence =
          controller.eventFormStateStreamValue.value.occurrences.single;
      expect(occurrence.relatedAccountProfileIds, isEmpty);
      expect(occurrence.relatedAccountProfiles, isEmpty);
      expect(occurrence.programmingItems.single.accountProfileIds, isEmpty);
      expect(occurrence.programmingItems.single.linkedAccountProfiles, isEmpty);
      expect(occurrence.programmingItems.single.title, 'Show principal');
    },
  );

  test(
    'selectSpecificDateFilter expands temporal buckets and clearing restores defaults',
    () {
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      controller.selectSpecificDateFilter(DateTime(2026, 4, 12));

      expect(
        controller.temporalFilterStreamValue.value,
        equals(TenantAdminEventTemporalBucket.values.toSet()),
      );

      controller.clearSpecificDateFilter();

      expect(
        controller.temporalFilterStreamValue.value,
        equals(TenantAdminEventTemporalBucket.defaultSelection),
      );
      expect(controller.specificDateFilterStreamValue.value, isNull);
    },
  );

  test(
    'resetEventFilters clears specific date, venue, related profile, and restores default temporal selection',
    () {
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      controller.selectSpecificDateFilter(DateTime(2026, 4, 12));
      controller.selectVenueFilter(
        tenantAdminAccountProfileFromRaw(
          id: 'venue-1',
          accountId: 'acc-venue-1',
          profileType: 'venue',
          displayName: 'Main Venue',
        ),
      );
      controller.selectRelatedAccountProfileFilter(
        tenantAdminAccountProfileFromRaw(
          id: 'profile-1',
          accountId: 'acc-profile-1',
          profileType: 'artist',
          displayName: 'DJ Test',
        ),
      );

      controller.resetEventFilters();

      expect(controller.specificDateFilterStreamValue.value, isNull);
      expect(controller.venueFilterStreamValue.value, isNull);
      expect(controller.relatedAccountProfileFilterStreamValue.value, isNull);
      expect(
        controller.temporalFilterStreamValue.value,
        equals(TenantAdminEventTemporalBucket.defaultSelection),
      );
    },
  );

  test('toggleTemporalFilter keeps at least one bucket selected', () {
    final controller = TenantAdminEventsController(
      eventsRepository: _TrackingEventsRepository(),
      taxonomiesRepository: _NoopTaxonomiesRepository(),
      landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
        'landlord-token',
      ),
    );

    controller.toggleTemporalFilter(TenantAdminEventTemporalBucket.future);

    expect(
      controller.temporalFilterStreamValue.value,
      equals(<TenantAdminEventTemporalBucket>{
        TenantAdminEventTemporalBucket.now,
      }),
    );

    controller.toggleTemporalFilter(TenantAdminEventTemporalBucket.now);

    expect(
      controller.temporalFilterStreamValue.value,
      equals(<TenantAdminEventTemporalBucket>{
        TenantAdminEventTemporalBucket.now,
      }),
    );
  });

  test(
    'event type taxonomy term loading ignores stale in-flight responses after empty transition',
    () async {
      final taxonomiesRepository = _DelayedBatchTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: taxonomiesRepository,
        batchTermsRepository: taxonomiesRepository,
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );
      controller.eventTypeCatalogStreamValue.addValue([
        TenantAdminEventType.withAllowedTaxonomies(
          nameValue: tenantAdminRequiredText('Shows'),
          slugValue: tenantAdminRequiredText('shows'),
          allowedTaxonomiesValue: tenantAdminTrimmedStringList(['genre']),
        ),
        TenantAdminEventType.withAllowedTaxonomies(
          nameValue: tenantAdminRequiredText('Plain'),
          slugValue: tenantAdminRequiredText('plain'),
          allowedTaxonomiesValue: tenantAdminTrimmedStringList(const []),
        ),
      ]);
      controller.taxonomiesStreamValue.addValue([
        tenantAdminTaxonomyDefinitionFromRaw(
          id: 'tax-genre',
          slug: 'genre',
          name: 'Genre',
          appliesTo: ['event'],
          icon: null,
          color: null,
        ),
      ]);

      controller.updateEventTypeSelection('shows');
      await taxonomiesRepository.waitForPendingRequest();
      expect(controller.taxonomyLoadingStreamValue.value, isTrue);
      controller.updateEventTypeSelection('plain');
      expect(controller.taxonomyLoadingStreamValue.value, isFalse);

      taxonomiesRepository.completePending(
        taxonomyId: 'tax-genre',
        termSlug: 'rock',
        termName: 'Rock',
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.taxonomyTermsBySlugStreamValue.value, isEmpty);
      expect(controller.taxonomyLoadingStreamValue.value, isFalse);
    },
  );

  test(
    'event type taxonomy term loading ignores stale in-flight responses after cache hit transition',
    () async {
      final taxonomiesRepository = _DelayedBatchTaxonomiesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: taxonomiesRepository,
        batchTermsRepository: taxonomiesRepository,
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );
      controller.eventTypeCatalogStreamValue.addValue([
        TenantAdminEventType.withAllowedTaxonomies(
          nameValue: tenantAdminRequiredText('Shows'),
          slugValue: tenantAdminRequiredText('shows'),
          allowedTaxonomiesValue: tenantAdminTrimmedStringList(['genre']),
        ),
        TenantAdminEventType.withAllowedTaxonomies(
          nameValue: tenantAdminRequiredText('Food'),
          slugValue: tenantAdminRequiredText('food'),
          allowedTaxonomiesValue: tenantAdminTrimmedStringList(['cuisine']),
        ),
      ]);
      controller.taxonomiesStreamValue.addValue([
        tenantAdminTaxonomyDefinitionFromRaw(
          id: 'tax-genre',
          slug: 'genre',
          name: 'Genre',
          appliesTo: ['event'],
          icon: null,
          color: null,
        ),
        tenantAdminTaxonomyDefinitionFromRaw(
          id: 'tax-cuisine',
          slug: 'cuisine',
          name: 'Cuisine',
          appliesTo: ['event'],
          icon: null,
          color: null,
        ),
      ]);

      controller.updateEventTypeSelection('shows');
      await taxonomiesRepository.waitForPendingRequest();
      taxonomiesRepository.completePending(
        taxonomyId: 'tax-genre',
        termSlug: 'rock',
        termName: 'Rock',
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.taxonomyTermsBySlugStreamValue.value.keys, ['genre']);

      controller.updateEventTypeSelection('food');
      await taxonomiesRepository.waitForPendingRequest();
      expect(controller.taxonomyLoadingStreamValue.value, isTrue);
      controller.updateEventTypeSelection('shows');
      expect(controller.taxonomyLoadingStreamValue.value, isFalse);

      taxonomiesRepository.completePending(
        taxonomyId: 'tax-cuisine',
        termSlug: 'pizza',
        termName: 'Pizza',
      );
      await Future<void>.delayed(Duration.zero);

      final termsBySlug = controller.taxonomyTermsBySlugStreamValue.value;
      expect(termsBySlug.keys, ['genre']);
      expect(termsBySlug['genre']?.single.slug, 'rock');
      expect(controller.taxonomyLoadingStreamValue.value, isFalse);
    },
  );

  test(
    'loadEventTypeFormTaxonomies reapplies persisted allowed taxonomies after stale taxonomy context cleared them',
    () async {
      final taxonomiesRepository = _StaticBatchTaxonomiesRepository(
        taxonomies: [
          tenantAdminTaxonomyDefinitionFromRaw(
            id: 'tax-genre',
            slug: 'genre',
            name: 'Genre',
            appliesTo: ['event'],
            icon: null,
            color: null,
          ),
          tenantAdminTaxonomyDefinitionFromRaw(
            id: 'tax-cuisine',
            slug: 'cuisine',
            name: 'Cuisine',
            appliesTo: ['event'],
            icon: null,
            color: null,
          ),
        ],
        termsByTaxonomyId: const {},
      );
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: taxonomiesRepository,
      );
      controller.taxonomiesStreamValue.addValue([
        tenantAdminTaxonomyDefinitionFromRaw(
          id: 'tax-stale',
          slug: 'stale',
          name: 'Stale',
          appliesTo: ['event'],
          icon: null,
          color: null,
        ),
      ]);

      controller.initEventTypeForm(
        existingType: TenantAdminEventType.withAllowedTaxonomies(
          idValue: tenantAdminOptionalText('type-1'),
          nameValue: tenantAdminRequiredText('Festival'),
          slugValue: tenantAdminRequiredText('festival'),
          allowedTaxonomiesValue: tenantAdminTrimmedStringList([
            'genre',
            'cuisine',
          ]),
        ),
      );

      expect(controller.selectedEventTypeAllowedTaxonomies, isEmpty);

      await controller.loadEventTypeFormTaxonomies();

      expect(controller.selectedEventTypeAllowedTaxonomies, [
        'genre',
        'cuisine',
      ]);
    },
  );

  test(
    'account-scoped loadFormDependencies uses dedicated event types endpoint and account-profile candidate pages',
    () async {
      final eventsRepository = _AccountScopedEventsRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
      );

      await controller.loadFormDependencies(accountSlug: 'my-account');

      expect(eventsRepository.fetchEventTypesCalls, 1);
      expect(eventsRepository.fetchEventsCalls, 0);
      expect(eventsRepository.accountProfileCandidatePageCalls, 2);
      expect(
        eventsRepository.lastAccountProfileCandidatesAccountSlug,
        'my-account',
      );
      expect(
        eventsRepository.candidateTypes,
        containsAll(<TenantAdminEventAccountProfileCandidateType>[
          TenantAdminEventAccountProfileCandidateType.physicalHost,
          TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
        ]),
      );
    },
  );

  test(
    'loadFormDependencies only fetches the first candidate page per type during bootstrap',
    () async {
      final eventsRepository = _BootstrapPagedCandidatesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
      );

      await controller.loadFormDependencies();

      expect(eventsRepository.accountProfileCandidatePageCalls, 2);
      expect(eventsRepository.candidatePageRequests, <
        (TenantAdminEventAccountProfileCandidateType, int)
      >[
        (TenantAdminEventAccountProfileCandidateType.physicalHost, 1),
        (TenantAdminEventAccountProfileCandidateType.relatedAccountProfile, 1),
      ]);
      expect(
        controller.venueCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        ['venue-bootstrap-1'],
      );
      expect(
        controller.relatedAccountProfileCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        ['artist-bootstrap-1'],
      );
      expect(controller.accountProfileCandidatesErrorStreamValue.value, isNull);
    },
  );

  test(
    'loadFormDependencies preserves an existing venue that is off the first bootstrap page',
    () async {
      final eventsRepository = _BootstrapPagedCandidatesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
      );
      final existingEvent = TenantAdminEvent(
        eventIdValue: tenantAdminRequiredText('evt-off-page-venue'),
        slugValue: tenantAdminRequiredText('evt-off-page-venue'),
        titleValue: tenantAdminRequiredText('Evento com venue fora da pagina'),
        contentValue: tenantAdminOptionalText('Conteudo'),
        type: TenantAdminEventType(
          idValue: tenantAdminOptionalText('type-1'),
          nameValue: tenantAdminRequiredText('Show'),
          slugValue: tenantAdminRequiredText('show'),
        ),
        location: TenantAdminEventLocation(
          modeValue: tenantAdminRequiredText('physical'),
          latitudeValue: tenantAdminOptionalDouble(-20.0),
          longitudeValue: tenantAdminOptionalDouble(-40.0),
        ),
        placeRef: TenantAdminEventPlaceRef(
          typeValue: tenantAdminRequiredText('account_profile'),
          idValue: tenantAdminRequiredText('venue-selected'),
        ),
        venueDisplayNameValue: tenantAdminOptionalText('Selected Venue'),
        occurrences: [
          TenantAdminEventOccurrence(
            dateTimeStartValue: tenantAdminDateTime(
              DateTime.utc(2026, 6, 7, 3),
            ),
          ),
        ],
        publication: TenantAdminEventPublication(
          statusValue: tenantAdminRequiredText('draft'),
        ),
      );

      controller.initEventForm(existingEvent: existingEvent);
      await controller.loadFormDependencies();

      expect(
        controller.eventFormStateStreamValue.value.selectedVenueId,
        'venue-selected',
      );
      expect(
        controller.venueCandidatesStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        ['venue-selected', 'venue-bootstrap-1'],
      );
      expect(
        controller.venueCandidatesStreamValue.value.first.displayName,
        'Selected Venue',
      );
    },
  );

  test(
    'bootstrap-seeded venue picker loads page 2 on next page request',
    () async {
      final eventsRepository = _BootstrapPagedCandidatesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
      );

      await controller.loadFormDependencies();
      await controller.prepareAccountProfilePicker(
        candidateType: TenantAdminEventAccountProfileCandidateType.physicalHost,
      );

      expect(
        controller.accountProfilePickerResultsStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        ['venue-bootstrap-1'],
      );
      expect(eventsRepository.candidatePageRequests, <
        (TenantAdminEventAccountProfileCandidateType, int)
      >[
        (TenantAdminEventAccountProfileCandidateType.physicalHost, 1),
        (TenantAdminEventAccountProfileCandidateType.relatedAccountProfile, 1),
      ]);

      await controller.loadNextAccountProfilePickerPage();

      expect(eventsRepository.candidatePageRequests, <
        (TenantAdminEventAccountProfileCandidateType, int)
      >[
        (TenantAdminEventAccountProfileCandidateType.physicalHost, 1),
        (TenantAdminEventAccountProfileCandidateType.relatedAccountProfile, 1),
        (TenantAdminEventAccountProfileCandidateType.physicalHost, 2),
      ]);
      expect(
        controller.accountProfilePickerResultsStreamValue.value
            .map((profile) => profile.id)
            .toList(growable: false),
        ['venue-bootstrap-1', 'venue-bootstrap-2'],
      );
      expect(controller.accountProfilePickerHasMoreStreamValue.value, isFalse);
    },
  );

  test(
    'loadFormDependencies fetches only selected event-type taxonomies via scoped slug lookup',
    () async {
      final eventsRepository = _ConfigurableEventTypesRepository([
        TenantAdminEventType.withAllowedTaxonomies(
          nameValue: tenantAdminRequiredText('Shows'),
          slugValue: tenantAdminRequiredText('shows'),
          allowedTaxonomiesValue: tenantAdminTrimmedStringList([
            'genre',
            'audience',
          ]),
        ),
      ]);
      final taxonomiesRepository = _StaticBatchTaxonomiesRepository(
        taxonomies: [
          tenantAdminTaxonomyDefinitionFromRaw(
            id: 'tax-genre',
            slug: 'genre',
            name: 'Genre',
            appliesTo: ['event'],
            icon: null,
            color: null,
          ),
          tenantAdminTaxonomyDefinitionFromRaw(
            id: 'tax-audience',
            slug: 'audience',
            name: 'Audience',
            appliesTo: ['event'],
            icon: null,
            color: null,
          ),
          tenantAdminTaxonomyDefinitionFromRaw(
            id: 'tax-cuisine',
            slug: 'cuisine',
            name: 'Cuisine',
            appliesTo: ['account_profile'],
            icon: null,
            color: null,
          ),
        ],
        termsByTaxonomyId: const {},
      );
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
        batchTermsRepository: taxonomiesRepository,
      );

      controller.initEventForm();
      await controller.loadFormDependencies();

      expect(taxonomiesRepository.fetchTaxonomiesBySlugsCalls, 1);
      expect(taxonomiesRepository.lastFetchedTaxonomySlugs, [
        'audience',
        'genre',
      ]);
      expect(taxonomiesRepository.lastFetchedAppliesTo, 'event');
      expect(taxonomiesRepository.fetchTaxonomiesPageCalls, 0);
      expect(
        controller.taxonomiesStreamValue.value
            .map((entry) => entry.slug)
            .toList(growable: false),
        ['audience', 'genre'],
      );
    },
  );

  test(
    'loadFormDependencies hydrates default event type and terms in controller',
    () async {
      final eventsRepository = _ConfigurableEventTypesRepository([
        TenantAdminEventType.withAllowedTaxonomies(
          nameValue: tenantAdminRequiredText('Shows'),
          slugValue: tenantAdminRequiredText('shows'),
          allowedTaxonomiesValue: tenantAdminTrimmedStringList(['genre']),
        ),
      ]);
      final taxonomiesRepository = _StaticBatchTaxonomiesRepository(
        taxonomies: [
          tenantAdminTaxonomyDefinitionFromRaw(
            id: 'tax-genre',
            slug: 'genre',
            name: 'Genre',
            appliesTo: ['event'],
            icon: null,
            color: null,
          ),
        ],
        termsByTaxonomyId: {
          'tax-genre': [
            TenantAdminTaxonomyTermDefinition(
              idValue: tenantAdminRequiredText('term-rock'),
              taxonomyIdValue: tenantAdminRequiredText('tax-genre'),
              slugValue: tenantAdminRequiredText('rock'),
              nameValue: tenantAdminRequiredText('Rock'),
            ),
          ],
        },
      );
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: taxonomiesRepository,
        batchTermsRepository: taxonomiesRepository,
      );

      controller.initEventForm();
      await controller.loadFormDependencies();

      expect(
        controller.eventFormStateStreamValue.value.selectedTypeSlug,
        'shows',
      );
      expect(controller.taxonomyTermsBySlugStreamValue.value.keys, ['genre']);
      expect(
        controller.taxonomyTermsBySlugStreamValue.value['genre']?.single.slug,
        'rock',
      );
    },
  );

  test(
    'occurrence taxonomy overrides are scoped to the selected event type',
    () {
      final controller = TenantAdminEventsController(
        eventsRepository: _TrackingEventsRepository(),
        taxonomiesRepository: _NoopTaxonomiesRepository(),
      );
      final showType = TenantAdminEventType.withAllowedTaxonomies(
        nameValue: tenantAdminRequiredText('Shows'),
        slugValue: tenantAdminRequiredText('shows'),
        allowedTaxonomiesValue: tenantAdminTrimmedStringList(['genre']),
      );
      final foodType = TenantAdminEventType.withAllowedTaxonomies(
        nameValue: tenantAdminRequiredText('Food'),
        slugValue: tenantAdminRequiredText('food'),
        allowedTaxonomiesValue: tenantAdminTrimmedStringList(['cuisine']),
      );
      controller.eventTypeCatalogStreamValue.addValue([showType, foodType]);
      controller.initEventForm(
        existingEvent: TenantAdminEvent(
          eventIdValue: tenantAdminRequiredText('evt-1'),
          slugValue: tenantAdminRequiredText('evt-1'),
          titleValue: tenantAdminRequiredText('Evento'),
          contentValue: tenantAdminOptionalText('Conteudo'),
          type: showType,
          occurrences: [
            TenantAdminEventOccurrence(
              dateTimeStartValue: tenantAdminDateTime(
                DateTime.utc(2026, 4, 5, 20),
              ),
            ),
          ],
          publication: TenantAdminEventPublication(
            statusValue: tenantAdminRequiredText('draft'),
          ),
        ),
      );

      final occurrenceKey = controller.primaryOccurrenceKey();
      expect(occurrenceKey, isNotNull);

      controller.toggleOccurrenceTaxonomyTerm(
        occurrenceKey: occurrenceKey!,
        taxonomySlug: 'genre',
        termSlug: 'rock',
        isSelected: true,
      );
      controller.toggleOccurrenceTaxonomyTerm(
        occurrenceKey: occurrenceKey,
        taxonomySlug: 'cuisine',
        termSlug: 'italian',
        isSelected: true,
      );

      expect(
        controller
            .occurrenceForKey(occurrenceKey)
            ?.taxonomyTerms
            .map((term) => '${term.type}:${term.value}')
            .toList(growable: false),
        ['genre:rock'],
      );

      controller.updateEventTypeSelection('food');

      expect(
        controller.occurrenceForKey(occurrenceKey)?.taxonomyTerms,
        isEmpty,
      );

      controller.toggleOccurrenceTaxonomyTerm(
        occurrenceKey: occurrenceKey,
        taxonomySlug: 'cuisine',
        termSlug: 'italian',
        isSelected: true,
      );

      expect(
        controller
            .occurrenceForKey(occurrenceKey)
            ?.taxonomyTerms
            .map((term) => '${term.type}:${term.value}')
            .toList(growable: false),
        ['cuisine:italian'],
      );
    },
  );

  test(
    'account-scoped submitCreate does not refresh tenant-admin events list',
    () async {
      final eventsRepository = _AccountScopedEventsRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
      );

      final created = await controller.submitCreate(
        _buildDraft(),
        accountSlug: 'my-account',
      );

      expect(created, isNotNull);
      expect(eventsRepository.createOwnCalls, 1);
      expect(eventsRepository.fetchEventsPageCalls, 0);
      expect(controller.submitErrorMessageStreamValue.value, isNull);
    },
  );

  test('submitCreate ignores concurrent submission while loading', () async {
    final eventsRepository = _AccountScopedEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    final first = controller.submitCreate(
      _buildDraft(),
      accountSlug: 'my-account',
    );
    final second = controller.submitCreate(
      _buildDraft(),
      accountSlug: 'my-account',
    );

    final secondResult = await second;
    await first;

    expect(secondResult, isNull);
    expect(eventsRepository.createOwnCalls, 1);
  });

  test(
    'tenant scope change without landlord token skips admin events load',
    () async {
      final eventsRepository = _TrackingEventsRepository();
      final tenantScope = _FakeTenantScope();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        tenantScope: tenantScope,
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(''),
      );

      tenantScope.selectTenantDomain('guarappari.belluga.space');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(eventsRepository.fetchEventsCalls, 0);
      expect(eventsRepository.fetchEventsPageCalls, 0);
      expect(controller.eventsStreamValue.value, isEmpty);
      expect(controller.eventsErrorStreamValue.value, isNull);
    },
  );

  test(
    'saveEventType sends null description when edit description is cleared',
    () async {
      final eventsRepository = _EventTypeUpdateTrackingRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      await controller.saveEventType(
        name: 'Show',
        slug: 'show',
        description: '   ',
        existingType: TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439011'),
          nameValue: tenantAdminRequiredText('Show'),
          slugValue: tenantAdminRequiredText('show'),
          descriptionValue: tenantAdminOptionalText('Legacy description'),
        ),
      );

      expect(eventsRepository.lastUpdateDescription, isNull);
    },
  );

  test(
    'saveEventType delegates canonical visual mutation when requested',
    () async {
      final eventsRepository = _EventTypeVisualTrackingRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
        landlordAuthRepository: _FakeLandlordAuthRepositoryWithToken(
          'landlord-token',
        ),
      );

      await controller.saveEventType(
        name: 'Festival',
        slug: 'festival',
        description: 'Tipo com imagem',
        visual: TenantAdminPoiVisual.image(
          imageSource: TenantAdminPoiVisualImageSource.typeAsset,
        ),
        typeAssetUpload: tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'festival-type.png',
        ),
        removeTypeAsset: true,
        includeVisual: true,
        existingType: TenantAdminEventType(
          idValue: tenantAdminOptionalText('507f1f77bcf86cd799439011'),
          nameValue: tenantAdminRequiredText('Show'),
          slugValue: tenantAdminRequiredText('show'),
        ),
      );

      expect(eventsRepository.visualUpdateCalls, 1);
      expect(eventsRepository.lastVisual?.mode, TenantAdminPoiVisualMode.image);
      expect(
        eventsRepository.lastVisual?.imageSource,
        TenantAdminPoiVisualImageSource.typeAsset,
      );
      expect(eventsRepository.lastRemoveTypeAsset, isTrue);
      expect(eventsRepository.lastTypeAssetUpload, isNotNull);
    },
  );

  test(
    'related account profile search is backend-driven, paginated, and resets on query change',
    () async {
      final eventsRepository =
          _SearchableRelatedAccountProfileCandidatesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
      );

      await controller.loadFormDependencies();
      await controller.prepareRelatedAccountProfilePicker();

      expect(eventsRepository.searchRequests, [('', 1)]);

      controller.updateRelatedAccountProfileSearchQuery('zulu');
      await controller.retryRelatedAccountProfileSearch();

      expect(
        controller.relatedAccountProfileSearchResultsStreamValue.value
            .map((profile) => profile.displayName)
            .toList(growable: false),
        ['Zulu Artist 1'],
      );
      expect(eventsRepository.searchRequests.last, ('zulu', 1));

      await controller.loadNextRelatedAccountProfileSearchPage();

      expect(
        controller.relatedAccountProfileSearchResultsStreamValue.value
            .map((profile) => profile.displayName)
            .toList(growable: false),
        ['Zulu Artist 1', 'Zulu Artist 2'],
      );
      expect(eventsRepository.searchRequests.last, ('zulu', 2));

      controller.updateRelatedAccountProfileSearchQuery('echo');
      await controller.retryRelatedAccountProfileSearch();

      expect(
        controller.relatedAccountProfileSearchResultsStreamValue.value
            .map((profile) => profile.displayName)
            .toList(growable: false),
        ['Echo Artist'],
      );
      expect(eventsRepository.searchRequests, [
        ('', 1),
        ('zulu', 1),
        ('zulu', 2),
        ('echo', 1),
      ]);
    },
  );

  test(
    'nested group related account profile search backfills later candidate pages into the known cache',
    () async {
      final eventsRepository = _NestedGroupLaterPageCandidatesRepository();
      final controller = TenantAdminEventsController(
        eventsRepository: eventsRepository,
        taxonomiesRepository: _NoopTaxonomiesRepository(),
      );

      await controller.loadFormDependencies();

      expect(
        controller.relatedAccountProfileCandidatesStreamValue.value
            .map((profile) => profile.displayName)
            .toList(growable: false),
        contains('Legacy Artist Page 1 001'),
      );

      await controller.searchRelatedAccountProfileCandidatesForNestedGroups(
        '021',
      );

      expect(
        controller.relatedAccountProfileCandidatesStreamValue.value
            .map((profile) => profile.displayName)
            .toList(growable: false),
        contains('Legacy Artist Page 2 021'),
      );
      expect(eventsRepository.searchRequests, [
        ('', 1),
        ('021', 1),
        ('021', 2),
      ]);
    },
  );

  test('inspectLegacyEventParties delegates to repository', () async {
    final eventsRepository = _LegacySummaryTrackingEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    final summary = await controller.inspectLegacyEventParties();

    expect(eventsRepository.inspectCalls, 1);
    expect(summary.invalid, 3);
  });

  test('repairLegacyEventParties delegates and reloads events', () async {
    final eventsRepository = _LegacySummaryTrackingEventsRepository();
    final controller = TenantAdminEventsController(
      eventsRepository: eventsRepository,
      taxonomiesRepository: _NoopTaxonomiesRepository(),
    );

    final summary = await controller.repairLegacyEventParties();

    expect(eventsRepository.repairCalls, 1);
    expect(eventsRepository.fetchEventsPageCalls, 1);
    expect(summary.repaired, 3);
  });
}

TenantAdminEvent _buildEventDetailFixture({
  required String eventId,
  required String title,
}) {
  return TenantAdminEvent(
    eventIdValue: tenantAdminRequiredText(eventId),
    slugValue: tenantAdminRequiredText('$eventId-slug'),
    titleValue: tenantAdminRequiredText(title),
    contentValue: tenantAdminOptionalText('Detailed content'),
    type: TenantAdminEventType(
      idValue: tenantAdminOptionalText('type-1'),
      nameValue: tenantAdminRequiredText('Show'),
      slugValue: tenantAdminRequiredText('show'),
    ),
    occurrences: <TenantAdminEventOccurrence>[
      TenantAdminEventOccurrence(
        occurrenceIdValue: tenantAdminOptionalText('$eventId-occurrence'),
        dateTimeStartValue: tenantAdminDateTime(DateTime.utc(2026, 6, 24, 18)),
      ),
    ],
    publication: TenantAdminEventPublication(
      statusValue: tenantAdminRequiredText('draft'),
    ),
  );
}

TenantAdminEventDraft _buildDraft() {
  return TenantAdminEventDraft(
    titleValue: tenantAdminRequiredText('My event'),
    contentValue: tenantAdminOptionalText('Content'),
    type: TenantAdminEventType(
      nameValue: tenantAdminRequiredText('Show'),
      slugValue: tenantAdminRequiredText('show'),
    ),
    occurrences: [
      TenantAdminEventOccurrence(
        dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 3, 5, 20)),
      ),
    ],
    publication: TenantAdminEventPublication(
      statusValue: tenantAdminRequiredText('draft'),
    ),
  );
}

class _FailingDeleteEventsRepository extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {
    throw StateError('delete failed');
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
  fetchLegacyEventPartiesSummary() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }

  @override
  Future<TenantAdminEvent> fetchEvent(
    TenantAdminEventsRepoString eventIdOrSlug,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    return <TenantAdminEvent>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminAccountProfile>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
  repairLegacyEventParties() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }
}

class _NoopTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements
        TenantAdminTaxonomiesRepositoryContract,
        TenantAdminTaxonomiesScopedLookupRepositoryContract {
  int fetchTaxonomiesPageCalls = 0;
  int fetchTaxonomiesBySlugsCalls = 0;
  List<String> lastFetchedTaxonomySlugs = const <String>[];
  String? lastFetchedAppliesTo;

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {}

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {}

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return <TenantAdminTaxonomyDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
  fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    fetchTaxonomiesPageCalls += 1;
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomiesBySlugs({
    required List<TenantAdminTaxRepoString> slugs,
    TenantAdminTaxRepoString? appliesTo,
  }) async {
    fetchTaxonomiesBySlugsCalls += 1;
    lastFetchedTaxonomySlugs = slugs
        .map((entry) => entry.value)
        .toList(growable: false);
    lastFetchedAppliesTo = appliesTo?.value;
    final available = await fetchTaxonomies();
    final allowedSlugs = slugs
        .map((entry) => entry.value.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet();
    final appliesToFilter = appliesTo?.value.trim();
    return available
        .where((taxonomy) => allowedSlugs.contains(taxonomy.slug))
        .where(
          (taxonomy) =>
              appliesToFilter == null ||
              appliesToFilter.isEmpty ||
              taxonomy.appliesTo.contains(appliesToFilter),
        )
        .toList(growable: false);
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return <TenantAdminTaxonomyTermDefinition>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
  fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyTermDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) async {
    throw UnimplementedError();
  }
}

class _TrackingEventsRepository extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  int fetchEventsCalls = 0;
  int fetchEventsPageCalls = 0;
  String? lastLoadSpecificDate;
  String? lastLoadVenueProfileId;
  String? lastLoadRelatedAccountProfileId;
  Set<TenantAdminEventTemporalBucket>? lastTemporalBuckets;

  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(
    TenantAdminEventsRepoString eventIdOrSlug,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    fetchEventsCalls += 1;
    lastLoadSpecificDate = specificDate?.value;
    lastLoadVenueProfileId = venueProfileId?.value;
    lastLoadRelatedAccountProfileId = relatedAccountProfileId?.value;
    lastTemporalBuckets = temporalBuckets;
    return <TenantAdminEvent>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    fetchEventsPageCalls += 1;
    lastLoadSpecificDate = specificDate?.value;
    lastLoadVenueProfileId = venueProfileId?.value;
    lastLoadRelatedAccountProfileId = relatedAccountProfileId?.value;
    lastTemporalBuckets = temporalBuckets;
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminAccountProfile>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
  fetchLegacyEventPartiesSummary() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
  repairLegacyEventParties() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }
}

class _FailingFilteredLoadEventsRepository extends _TrackingEventsRepository {
  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    lastLoadSpecificDate = specificDate?.value;
    lastLoadVenueProfileId = venueProfileId?.value;
    lastLoadRelatedAccountProfileId = relatedAccountProfileId?.value;
    lastTemporalBuckets = temporalBuckets;

    throw StateError('filtered load failed');
  }
}

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  @override
  final StreamValue<String?> selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl {
    final selected = selectedTenantDomain?.trim() ?? '';
    if (selected.isEmpty) {
      return '';
    }
    final host = selected.contains('://')
        ? (Uri.tryParse(selected)?.host ?? selected)
        : selected;
    return 'https://$host/admin/api';
  }

  @override
  void clearSelectedTenantDomain() {
    selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(Object tenantDomain) {
    selectedTenantDomainStreamValue.addValue(
      tenantDomain is String
          ? tenantDomain
          : (tenantDomain as dynamic).value as String,
    );
  }
}

class _DelayedBatchTaxonomiesRepository extends _NoopTaxonomiesRepository
    implements TenantAdminTaxonomiesBatchTermsRepositoryContract {
  Completer<TenantAdminTaxonomyTermsByTaxonomyId>? _pendingCompleter;
  Completer<void>? _pendingStarted;

  Future<void> waitForPendingRequest() async {
    final started = _pendingStarted;
    if (started != null && !started.isCompleted) {
      await started.future;
    }
  }

  void completePending({
    required String taxonomyId,
    required String termSlug,
    required String termName,
  }) {
    final completer = _pendingCompleter;
    if (completer == null || completer.isCompleted) {
      throw StateError('No pending taxonomy batch request.');
    }
    completer.complete(
      TenantAdminTaxonomyTermsByTaxonomyId(
        entries: [
          TenantAdminTaxonomyTermsForTaxonomyId(
            taxonomyIdValue: tenantAdminRequiredText(taxonomyId),
            terms: [
              TenantAdminTaxonomyTermDefinition(
                idValue: tenantAdminRequiredText('$taxonomyId-$termSlug'),
                taxonomyIdValue: tenantAdminRequiredText(taxonomyId),
                slugValue: tenantAdminRequiredText(termSlug),
                nameValue: tenantAdminRequiredText(termName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Future<TenantAdminTaxonomyTermsByTaxonomyId> fetchTermsByTaxonomyIds({
    required List<TenantAdminTaxRepoString> taxonomyIds,
    TenantAdminTaxRepoInt? termLimit,
  }) {
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      throw StateError('A taxonomy batch request is already pending.');
    }
    _pendingCompleter = Completer<TenantAdminTaxonomyTermsByTaxonomyId>();
    _pendingStarted = Completer<void>()..complete();
    return _pendingCompleter!.future;
  }
}

class _StaticBatchTaxonomiesRepository extends _NoopTaxonomiesRepository
    implements TenantAdminTaxonomiesBatchTermsRepositoryContract {
  _StaticBatchTaxonomiesRepository({
    required this.taxonomies,
    required this.termsByTaxonomyId,
  });

  final List<TenantAdminTaxonomyDefinition> taxonomies;
  final Map<String, List<TenantAdminTaxonomyTermDefinition>> termsByTaxonomyId;

  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return taxonomies;
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
  fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: page.value == 1 ? taxonomies : <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermsByTaxonomyId> fetchTermsByTaxonomyIds({
    required List<TenantAdminTaxRepoString> taxonomyIds,
    TenantAdminTaxRepoInt? termLimit,
  }) async {
    return TenantAdminTaxonomyTermsByTaxonomyId(
      entries: [
        for (final taxonomyId in taxonomyIds)
          TenantAdminTaxonomyTermsForTaxonomyId(
            taxonomyIdValue: tenantAdminRequiredText(taxonomyId.value),
            terms:
                termsByTaxonomyId[taxonomyId.value] ??
                const <TenantAdminTaxonomyTermDefinition>[],
          ),
      ],
    );
  }
}

class _FakeLandlordAuthRepositoryWithToken
    implements LandlordAuthRepositoryContract {
  _FakeLandlordAuthRepositoryWithToken(this._token);

  String _token;

  @override
  bool get hasValidSession => _token.trim().isNotEmpty;

  @override
  String get token => _token;

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
    LandlordAuthRepositoryContractPrimString email,
    LandlordAuthRepositoryContractPrimString password,
  ) async {}

  @override
  Future<void> logout() async {
    _token = '';
  }
}

class _AccountScopedEventsRepository extends TenantAdminEventsRepositoryContract
    with TenantAdminEventsPaginationMixin {
  int fetchEventTypesCalls = 0;
  int fetchEventsCalls = 0;
  int fetchEventsPageCalls = 0;
  int accountProfileCandidatePageCalls = 0;
  int createOwnCalls = 0;
  String? lastAccountProfileCandidatesAccountSlug;
  final List<TenantAdminEventAccountProfileCandidateType> candidateTypes =
      <TenantAdminEventAccountProfileCandidateType>[];

  @override
  Future<TenantAdminEvent> createEvent({
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminEvent> createOwnEvent({
    required TenantAdminEventsRepoString accountSlug,
    required TenantAdminEventDraft draft,
  }) async {
    createOwnCalls += 1;
    return TenantAdminEvent(
      eventIdValue: tenantAdminRequiredText('evt-own'),
      slugValue: tenantAdminRequiredText('own-event'),
      titleValue: tenantAdminRequiredText(draft.title),
      contentValue: tenantAdminOptionalText(draft.content),
      type: draft.type,
      publication: draft.publication,
      occurrences: draft.occurrences,
      relatedAccountProfileIdValues: draft.relatedAccountProfileIds,
      taxonomyTerms: draft.taxonomyTerms,
      location: draft.location,
      placeRef: draft.placeRef,
    );
  }

  @override
  Future<void> deleteEvent(TenantAdminEventsRepoString eventId) async {}

  @override
  Future<TenantAdminEvent> fetchEvent(
    TenantAdminEventsRepoString eventIdOrSlug,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    fetchEventTypesCalls += 1;
    return [
      TenantAdminEventType(
        idValue: tenantAdminOptionalText('507f1f77bcf86cd799439099'),
        nameValue: tenantAdminRequiredText('Show'),
        slugValue: tenantAdminRequiredText('show'),
        descriptionValue: tenantAdminOptionalText('Tipo de evento: Show'),
      ),
    ];
  }

  @override
  Future<List<TenantAdminEvent>> fetchEvents({
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    fetchEventsCalls += 1;
    return <TenantAdminEvent>[];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminEvent>> fetchEventsPage({
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? specificDate,
    TenantAdminEventsRepoString? status,
    TenantAdminEventsRepoString? venueProfileId,
    TenantAdminEventsRepoString? relatedAccountProfileId,
    TenantAdminEventsRepoBool? archived,
    Set<TenantAdminEventTemporalBucket>? temporalBuckets,
  }) async {
    fetchEventsPageCalls += 1;
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminEvent>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    accountProfileCandidatePageCalls += 1;
    lastAccountProfileCandidatesAccountSlug = accountSlug?.value;
    candidateTypes.add(candidateType);
    return tenantAdminPagedResultFromRaw(
      items: const <TenantAdminAccountProfile>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminEvent> updateEvent({
    required TenantAdminEventsRepoString eventId,
    required TenantAdminEventDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
  fetchLegacyEventPartiesSummary() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
  repairLegacyEventParties() async {
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(0),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(0),
      failedValue: TenantAdminCountValue(0),
    );
  }
}

class _ConfigurableEventTypesRepository extends _AccountScopedEventsRepository {
  _ConfigurableEventTypesRepository(this.eventTypes);

  final List<TenantAdminEventType> eventTypes;

  @override
  Future<List<TenantAdminEventType>> fetchEventTypes() async {
    fetchEventTypesCalls += 1;
    return List<TenantAdminEventType>.unmodifiable(eventTypes);
  }
}

class _BootstrapPagedCandidatesRepository
    extends _AccountScopedEventsRepository {
  final List<(TenantAdminEventAccountProfileCandidateType, int)>
  candidatePageRequests =
      <(TenantAdminEventAccountProfileCandidateType, int)>[];

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    accountProfileCandidatePageCalls += 1;
    candidateTypes.add(candidateType);
    lastAccountProfileCandidatesAccountSlug = accountSlug?.value;
    candidatePageRequests.add((candidateType, page.value));

    final item = switch (candidateType) {
      TenantAdminEventAccountProfileCandidateType.physicalHost =>
        tenantAdminAccountProfileFromRaw(
          id: 'venue-bootstrap-${page.value}',
          accountId: 'account-venue-${page.value}',
          profileType: 'venue',
          displayName: 'Bootstrap Venue ${page.value}',
        ),
      TenantAdminEventAccountProfileCandidateType.relatedAccountProfile =>
        tenantAdminAccountProfileFromRaw(
          id: 'artist-bootstrap-${page.value}',
          accountId: 'account-artist-${page.value}',
          profileType: 'artist',
          displayName: 'Bootstrap Artist ${page.value}',
        ),
    };

    return tenantAdminPagedResultFromRaw(
      items: [item],
      hasMore: page.value == 1,
    );
  }
}

class _EventTypeUpdateTrackingRepository
    extends _AccountScopedEventsRepository {
  String? lastUpdateDescription;

  @override
  Future<TenantAdminEventType> updateEventType({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
  }) async {
    lastUpdateDescription = description?.value;
    return TenantAdminEventType(
      idValue: tenantAdminOptionalText(eventTypeId.value),
      nameValue: tenantAdminRequiredText(name?.value ?? 'Show'),
      slugValue: tenantAdminRequiredText(slug?.value ?? 'show'),
      descriptionValue: tenantAdminOptionalText(description?.value),
    );
  }
}

class _EventTypeVisualTrackingRepository
    extends _AccountScopedEventsRepository {
  int visualUpdateCalls = 0;
  TenantAdminPoiVisual? lastVisual;
  TenantAdminMediaUpload? lastTypeAssetUpload;
  bool? lastRemoveTypeAsset;

  @override
  Future<TenantAdminEventType> updateEventTypeWithVisual({
    required TenantAdminEventsRepoString eventTypeId,
    TenantAdminEventsRepoString? name,
    TenantAdminEventsRepoString? slug,
    TenantAdminEventsRepoString? description,
    List<TenantAdminEventsRepoString>? allowedTaxonomies,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    TenantAdminEventsRepoBool? removeTypeAsset,
  }) async {
    visualUpdateCalls += 1;
    lastVisual = visual;
    lastTypeAssetUpload = typeAssetUpload;
    lastRemoveTypeAsset = removeTypeAsset?.value;
    return TenantAdminEventType(
      idValue: tenantAdminOptionalText(eventTypeId.value),
      nameValue: tenantAdminRequiredText(name?.value ?? 'Festival'),
      slugValue: tenantAdminRequiredText(slug?.value ?? 'festival'),
      descriptionValue: tenantAdminOptionalText(description?.value),
      visual: visual,
    );
  }
}

class _LegacySummaryTrackingEventsRepository extends _TrackingEventsRepository {
  int inspectCalls = 0;
  int repairCalls = 0;

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
  fetchLegacyEventPartiesSummary() async {
    inspectCalls += 1;
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(7),
      invalidValue: TenantAdminCountValue(3),
      repairedValue: TenantAdminCountValue(0),
      unchangedValue: TenantAdminCountValue(4),
      failedValue: TenantAdminCountValue(0),
    );
  }

  @override
  Future<TenantAdminLegacyEventPartiesSummary>
  repairLegacyEventParties() async {
    repairCalls += 1;
    return TenantAdminLegacyEventPartiesSummary(
      scannedValue: TenantAdminCountValue(7),
      invalidValue: TenantAdminCountValue(0),
      repairedValue: TenantAdminCountValue(3),
      unchangedValue: TenantAdminCountValue(4),
      failedValue: TenantAdminCountValue(0),
    );
  }
}

class _SearchableRelatedAccountProfileCandidatesRepository
    extends _AccountScopedEventsRepository {
  final List<(String, int)> searchRequests = <(String, int)>[];

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (candidateType ==
        TenantAdminEventAccountProfileCandidateType.physicalHost) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminAccountProfile>[],
        hasMore: false,
      );
    }

    final normalizedSearch = search?.value.trim().toLowerCase() ?? '';
    searchRequests.add((normalizedSearch, page.value));

    final result = switch ((normalizedSearch, page.value)) {
      ('', 1) => (
        <TenantAdminAccountProfile>[
          tenantAdminAccountProfileFromRaw(
            id: 'artist-bootstrap',
            accountId: 'acc-bootstrap',
            profileType: 'artist',
            displayName: 'Bootstrap Artist',
          ),
        ],
        true,
      ),
      ('', 2) => (
        <TenantAdminAccountProfile>[
          tenantAdminAccountProfileFromRaw(
            id: 'artist-bootstrap-2',
            accountId: 'acc-bootstrap-2',
            profileType: 'artist',
            displayName: 'Bootstrap Artist 2',
          ),
        ],
        false,
      ),
      ('zulu', 1) => (
        <TenantAdminAccountProfile>[
          tenantAdminAccountProfileFromRaw(
            id: 'artist-zulu-1',
            accountId: 'acc-zulu-1',
            profileType: 'artist',
            displayName: 'Zulu Artist 1',
          ),
        ],
        true,
      ),
      ('zulu', 2) => (
        <TenantAdminAccountProfile>[
          tenantAdminAccountProfileFromRaw(
            id: 'artist-zulu-2',
            accountId: 'acc-zulu-2',
            profileType: 'artist',
            displayName: 'Zulu Artist 2',
          ),
        ],
        false,
      ),
      ('echo', 1) => (
        <TenantAdminAccountProfile>[
          tenantAdminAccountProfileFromRaw(
            id: 'artist-echo-1',
            accountId: 'acc-echo-1',
            profileType: 'artist',
            displayName: 'Echo Artist',
          ),
        ],
        false,
      ),
      _ => (const <TenantAdminAccountProfile>[], false),
    };

    return tenantAdminPagedResultFromRaw(items: result.$1, hasMore: result.$2);
  }
}

class _NestedGroupLaterPageCandidatesRepository
    extends _AccountScopedEventsRepository {
  final List<(String, int)> searchRequests = <(String, int)>[];

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchEventAccountProfileCandidatesPage({
    required TenantAdminEventAccountProfileCandidateType candidateType,
    required TenantAdminEventsRepoInt page,
    required TenantAdminEventsRepoInt pageSize,
    TenantAdminEventsRepoString? search,
    TenantAdminEventsRepoString? accountSlug,
  }) async {
    if (candidateType ==
        TenantAdminEventAccountProfileCandidateType.physicalHost) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminAccountProfile>[],
        hasMore: false,
      );
    }

    final normalizedSearch = search?.value.trim().toLowerCase() ?? '';
    searchRequests.add((normalizedSearch, page.value));

    final firstPageItems = List<TenantAdminAccountProfile>.generate(
      20,
      (index) => tenantAdminAccountProfileFromRaw(
        id: 'artist-page-1-${index + 1}',
        accountId: 'acc-page-1-${index + 1}',
        profileType: 'artist',
        displayName:
            'Legacy Artist Page 1 ${(index + 1).toString().padLeft(3, '0')}',
      ),
      growable: false,
    );

    final pageTwoItems = <TenantAdminAccountProfile>[
      tenantAdminAccountProfileFromRaw(
        id: 'artist-page-2-021',
        accountId: 'acc-page-2-021',
        profileType: 'artist',
        displayName: 'Legacy Artist Page 2 021',
      ),
    ];

    return tenantAdminPagedResultFromRaw(
      items: page.value == 1 ? firstPageItems : pageTwoItems,
      hasMore: page.value == 1,
    );
  }
}
