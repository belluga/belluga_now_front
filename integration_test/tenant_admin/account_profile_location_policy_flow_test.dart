import 'dart:io';

import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/landlord_auth_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_lookup_domain_value.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_account_profiles_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_accounts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_events_repository.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_selected_tenant_repository.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/screens/tenant_admin_profile_type_form_screen.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import '../support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const adminEmailDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_EMAIL',
    defaultValue: '',
  );
  const adminPasswordDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_PASSWORD',
    defaultValue: '',
  );
  const landlordDomainDefine = String.fromEnvironment(
    'LANDLORD_DOMAIN',
    defaultValue: 'https://belluga.site',
  );
  const tenantDomainDefine = String.fromEnvironment(
    'TENANT_ADMIN_TEST_DOMAIN',
    defaultValue: 'guarappari.belluga.space',
  );
  const tenantAdminRouteDomainDefine = String.fromEnvironment(
    'TENANT_ADMIN_ROUTE_DOMAIN',
    defaultValue: '',
  );
  const deviceLoopbackPortDefine = int.fromEnvironment(
    'DEVICE_LOOPBACK_PORT',
    defaultValue: 0,
  );

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'location policy drives dependent capabilities and persists with CAS',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 2000);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      final controller = _RecordingProfileTypesController();
      GetIt.I.registerSingleton<TenantAdminProfileTypesController>(controller);

      await tester.pumpWidget(
        MaterialApp(
          home: TenantAdminProfileTypeFormScreen(
            definition: _locationProfileType(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final policy = find.byKey(
        const ValueKey<String>('profileTypeCapability_location_policy'),
      );
      final mapPoi = find.byKey(
        const ValueKey<String>('profileTypeCapability_is_map_poi_enabled'),
      );
      final physicalHost = find.byKey(
        const ValueKey<String>(
          'profileTypeCapability_is_physical_host_enabled',
        ),
      );
      final referenceLocation = find.byKey(
        const ValueKey<String>(
          'profileTypeCapability_is_reference_location_enabled',
        ),
      );

      expect(tester.widget<SwitchListTile>(mapPoi).onChanged, isNull);
      expect(tester.widget<SwitchListTile>(physicalHost).onChanged, isNull);
      expect(
        tester.widget<SwitchListTile>(referenceLocation).onChanged,
        isNull,
      );

      await tester.ensureVisible(policy);
      await tester.tap(policy);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Optional').last);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(mapPoi).onChanged, isNotNull);
      expect(tester.widget<SwitchListTile>(physicalHost).onChanged, isNotNull);
      expect(
        tester.widget<SwitchListTile>(referenceLocation).onChanged,
        isNotNull,
      );

      await tester.tap(mapPoi);
      await tester.tap(physicalHost);
      await tester.tap(referenceLocation);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Salvar alteracoes'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Salvar alteracoes'));
      await tester.pumpAndSettle();

      expect(controller.submitCalls, 1);
      expect(controller.expectedCapabilityRevision, 7);
      expect(controller.savedCapabilities?.locationPolicy, 'optional');
      expect(controller.savedCapabilities?.isMapPoiEnabled, isTrue);
      expect(controller.savedCapabilities?.isPhysicalHostEnabled, isTrue);
      expect(controller.savedCapabilities?.isReferenceLocationEnabled, isTrue);

      await tester.ensureVisible(policy);
      await tester.tap(policy);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disabled').last);
      await tester.pumpAndSettle();

      expect(controller.currentCapabilities.locationPolicy, 'disabled');
      expect(controller.currentCapabilities.isMapPoiEnabled, isFalse);
      expect(controller.currentCapabilities.isPhysicalHostEnabled, isFalse);
      expect(
        controller.currentCapabilities.isReferenceLocationEnabled,
        isFalse,
      );
      expect(tester.widget<SwitchListTile>(mapPoi).onChanged, isNull);

      await tester.ensureVisible(policy);
      await tester.tap(policy);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Required').last);
      await tester.pumpAndSettle();

      expect(controller.currentCapabilities.locationPolicy, 'required');
      expect(controller.currentCapabilities.requiresLocation, isTrue);
      expect(tester.widget<SwitchListTile>(mapPoi).onChanged, isNotNull);
    },
  );

  testWidgets(
    'real backend enforces location policy, physical-host selection, conflict, and remediation',
    (tester) async {
      final adminEmail = _requireDefine(
        'LANDLORD_ADMIN_EMAIL',
        adminEmailDefine,
      );
      final adminPassword = _requireDefine(
        'LANDLORD_ADMIN_PASSWORD',
        adminPasswordDefine,
      );
      final expectedTenantHost = _normalizeHost(tenantDomainDefine);
      final tenantAdminRouteDomain = _normalizeScopeDomain(
        tenantAdminRouteDomainDefine.trim().isEmpty
            ? tenantDomainDefine
            : tenantAdminRouteDomainDefine,
      );
      final tenantAdminRouteHost = _normalizeHost(tenantAdminRouteDomain);
      final landlordOrigin = _normalizeOrigin(landlordDomainDefine);

      final authRepository = LandlordAuthRepository(
        dio: _integrationDio(
          loopbackPort: deviceLoopbackPortDefine,
          options: BaseOptions(baseUrl: '$landlordOrigin/admin/api'),
        ),
      );
      final tenantScopeRepository = TenantAdminSelectedTenantRepository();
      final tenantsRepository = LandlordTenantsRepository(
        dio: _integrationDio(loopbackPort: deviceLoopbackPortDefine),
        landlordAuthRepository: authRepository,
        landlordOriginOverride: landlordOrigin,
      );
      final accountsRepository = TenantAdminAccountsRepository(
        dio: _integrationDio(loopbackPort: deviceLoopbackPortDefine),
        tenantScope: tenantScopeRepository,
      );
      final profilesRepository = TenantAdminAccountProfilesRepository(
        dio: _integrationDio(loopbackPort: deviceLoopbackPortDefine),
        tenantScope: tenantScopeRepository,
      );
      final eventsRepository = TenantAdminEventsRepository(
        dio: _integrationDio(loopbackPort: deviceLoopbackPortDefine),
        tenantScope: tenantScopeRepository,
      );

      GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(authRepository);

      final createdAccountSlugs = <String>[];
      final createdProfileTypes = <String>[];
      String? createdEventId;
      String? createdEventTypeId;

      try {
        await authRepository.init();
        await authRepository.loginWithEmailPassword(
          landlordAuthRepoString(adminEmail),
          landlordAuthRepoString(adminPassword),
        );
        expect(authRepository.hasValidSession, isTrue);

        final tenants = await tenantsRepository.fetchTenants();
        expect(tenants, isNotEmpty);
        final tenantOption = _resolveTenantByDomain(
          tenants,
          expectedTenantHost,
        );
        tenantScopeRepository.setAvailableTenants(tenants);
        tenantScopeRepository.selectTenant(tenantOption);
        if (tenantAdminRouteHost != expectedTenantHost) {
          tenantScopeRepository.selectTenantDomain(
            TenantLookupDomainValue()..parse(tenantAdminRouteDomain),
          );
        }

        final unique = DateTime.now().microsecondsSinceEpoch.toString();
        final optionalTypeKey = 'location-optional-$unique';
        final requiredTypeKey = 'location-required-$unique';
        final nonHostTypeKey = 'location-non-host-$unique';

        final disabledType = await profilesRepository.createProfileType(
          type: tenantAdminAccountProfilesRepoString(
            optionalTypeKey,
            isRequired: true,
          ),
          label: tenantAdminAccountProfilesRepoString(
            'Location Optional $unique',
            isRequired: true,
          ),
          capabilities: _locationCapabilities(
            policy: 'disabled',
            physicalHost: false,
          ),
        );
        createdProfileTypes.add(disabledType.type);

        final optionalType = await profilesRepository.updateProfileType(
          type: tenantAdminAccountProfilesRepoString(
            disabledType.type,
            isRequired: true,
          ),
          capabilities: _locationCapabilities(
            policy: 'optional',
            physicalHost: true,
          ),
          expectedCapabilityRevision: tenantAdminAccountProfilesRepoInt(
            disabledType.capabilityRevision,
            defaultValue: disabledType.capabilityRevision,
          ),
        );
        expect(optionalType.capabilities.locationPolicy, 'optional');
        expect(optionalType.capabilities.isPhysicalHostEnabled, isTrue);
        expect(
          optionalType.capabilityRevision,
          greaterThan(disabledType.capabilityRevision),
        );

        final requiredType = await profilesRepository.createProfileType(
          type: tenantAdminAccountProfilesRepoString(
            requiredTypeKey,
            isRequired: true,
          ),
          label: tenantAdminAccountProfilesRepoString(
            'Location Required $unique',
            isRequired: true,
          ),
          capabilities: _locationCapabilities(
            policy: 'required',
            physicalHost: true,
          ),
        );
        createdProfileTypes.add(requiredType.type);

        final nonHostType = await profilesRepository.createProfileType(
          type: tenantAdminAccountProfilesRepoString(
            nonHostTypeKey,
            isRequired: true,
          ),
          label: tenantAdminAccountProfilesRepoString(
            'Location Non Host $unique',
            isRequired: true,
          ),
          capabilities: _locationCapabilities(
            policy: 'optional',
            physicalHost: false,
          ),
        );
        createdProfileTypes.add(nonHostType.type);

        await expectLater(
          accountsRepository.createAccountOnboarding(
            name: _accountText('Required Missing $unique'),
            ownershipState: TenantAdminOwnershipState.tenantOwned,
            profileType: _accountText(requiredType.type),
          ),
          throwsA(
            isA<FormValidationFailure>().having(
              (error) => error.fieldErrors.containsKey('location'),
              'location validation',
              isTrue,
            ),
          ),
        );

        final optionalEdited = await accountsRepository.createAccountOnboarding(
          name: _accountText('Location Flow Edited $unique'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
          profileType: _accountText(optionalType.type),
        );
        createdAccountSlugs.add(optionalEdited.account.slug);
        expect(optionalEdited.accountProfile.location, isNull);

        final locatedOptional = await profilesRepository.updateAccountProfile(
          accountProfileId: tenantAdminAccountProfilesRepoString(
            optionalEdited.accountProfile.id,
            isRequired: true,
          ),
          aggregateRevision: _profileRevision(optionalEdited.accountProfile),
          location: _location(-20.61231, -40.49721),
          includeLocation: tenantAdminAccountProfilesRepoBool(true),
        );
        expect(
          locatedOptional.location?.latitude,
          closeTo(-20.61231, 0.000001),
        );
        expect(
          locatedOptional.location?.longitude,
          closeTo(-40.49721, 0.000001),
        );

        final optionalWithoutLocation = await accountsRepository
            .createAccountOnboarding(
              name: _accountText('Location Flow No Point $unique'),
              ownershipState: TenantAdminOwnershipState.tenantOwned,
              profileType: _accountText(optionalType.type),
            );
        createdAccountSlugs.add(optionalWithoutLocation.account.slug);

        final nonHostLocated = await accountsRepository.createAccountOnboarding(
          name: _accountText('Location Flow Non Host $unique'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
          profileType: _accountText(nonHostType.type),
          location: _location(-20.61331, -40.49621),
        );
        createdAccountSlugs.add(nonHostLocated.account.slug);

        final requiredLocated = await accountsRepository
            .createAccountOnboarding(
              name: _accountText('Location Flow Required $unique'),
              ownershipState: TenantAdminOwnershipState.tenantOwned,
              profileType: _accountText(requiredType.type),
              location: _location(-20.61431, -40.49521),
            );
        createdAccountSlugs.add(requiredLocated.account.slug);

        final requiredEdited = await profilesRepository.updateAccountProfile(
          accountProfileId: tenantAdminAccountProfilesRepoString(
            requiredLocated.accountProfile.id,
            isRequired: true,
          ),
          aggregateRevision: _profileRevision(requiredLocated.accountProfile),
          location: _location(-20.61531, -40.49421),
          includeLocation: tenantAdminAccountProfilesRepoBool(true),
        );
        final requiredReadback = await profilesRepository.fetchAccountProfile(
          tenantAdminAccountProfilesRepoString(
            requiredEdited.id,
            isRequired: true,
          ),
        );
        expect(
          requiredReadback.location?.latitude,
          closeTo(-20.61531, 0.000001),
        );
        expect(
          requiredReadback.location?.longitude,
          closeTo(-40.49421, 0.000001),
        );

        final candidates = await eventsRepository
            .fetchEventAccountProfileCandidatesPage(
              candidateType:
                  TenantAdminEventAccountProfileCandidateType.physicalHost,
              page: TenantAdminEventsRepoInt.fromRaw(1, defaultValue: 1),
              pageSize: TenantAdminEventsRepoInt.fromRaw(50, defaultValue: 50),
              search: TenantAdminEventsRepoString.fromRaw(
                'Location Flow',
                isRequired: true,
              ),
            );
        final candidateIds = candidates.items
            .map((candidate) => candidate.id)
            .toSet();
        expect(candidateIds, contains(locatedOptional.id));
        expect(candidateIds, contains(requiredEdited.id));
        expect(
          candidateIds,
          isNot(contains(optionalWithoutLocation.accountProfile.id)),
        );
        expect(candidateIds, isNot(contains(nonHostLocated.accountProfile.id)));

        final eventType = await eventsRepository.createEventType(
          name: TenantAdminEventsRepoString.fromRaw(
            'Location Flow Event $unique',
            isRequired: true,
          ),
          slug: TenantAdminEventsRepoString.fromRaw(
            'location-flow-event-$unique',
            isRequired: true,
          ),
        );
        createdEventTypeId = eventType.id;

        final event = await eventsRepository.createEvent(
          draft: _eventDraft(
            unique: unique,
            eventType: eventType,
            placeRefId: locatedOptional.id,
          ),
        );
        createdEventId = event.eventId;
        expect(event.placeRef?.type, 'account_profile');
        expect(event.placeRef?.id, locatedOptional.id);

        await expectLater(
          profilesRepository.updateAccountProfile(
            accountProfileId: tenantAdminAccountProfilesRepoString(
              locatedOptional.id,
              isRequired: true,
            ),
            aggregateRevision: _profileRevision(locatedOptional),
            includeLocation: tenantAdminAccountProfilesRepoBool(true),
          ),
          throwsA(
            isA<FormApiFailure>()
                .having((error) => error.statusCode, 'statusCode', 409)
                .having(
                  (error) => error.errorCode,
                  'errorCode',
                  'account_profile_location_in_use',
                ),
          ),
        );

        final remediatedEvent = await eventsRepository.updateEvent(
          eventId: TenantAdminEventsRepoString.fromRaw(
            event.eventId,
            isRequired: true,
          ),
          draft: _eventDraft(
            unique: unique,
            eventType: eventType,
            online: true,
            existingOccurrence: event.occurrences.single,
          ),
        );
        expect(remediatedEvent.placeRef, isNull);
        final eventReadback = await eventsRepository.fetchEvent(
          TenantAdminEventsRepoString.fromRaw(event.eventId, isRequired: true),
        );
        expect(eventReadback.placeRef, isNull);

        final profileAfterConflict = await profilesRepository
            .fetchAccountProfile(
              tenantAdminAccountProfilesRepoString(
                locatedOptional.id,
                isRequired: true,
              ),
            );
        final clearedProfile = await profilesRepository.updateAccountProfile(
          accountProfileId: tenantAdminAccountProfilesRepoString(
            locatedOptional.id,
            isRequired: true,
          ),
          aggregateRevision: _profileRevision(profileAfterConflict),
          includeLocation: tenantAdminAccountProfilesRepoBool(true),
        );
        expect(clearedProfile.location, isNull);
        final clearedReadback = await profilesRepository.fetchAccountProfile(
          tenantAdminAccountProfilesRepoString(
            locatedOptional.id,
            isRequired: true,
          ),
        );
        expect(clearedReadback.location, isNull);
      } finally {
        final eventId = createdEventId;
        if (eventId != null && eventId.trim().isNotEmpty) {
          try {
            await eventsRepository.deleteEvent(
              TenantAdminEventsRepoString.fromRaw(eventId, isRequired: true),
            );
          } catch (_) {
            // Best-effort cleanup for local integration data.
          }
        }
        await _cleanupAccounts(
          accountsRepository: accountsRepository,
          accountSlugs: createdAccountSlugs,
        );
        for (final profileType in createdProfileTypes.reversed) {
          try {
            await profilesRepository.deleteProfileType(
              tenantAdminAccountProfilesRepoString(
                profileType,
                isRequired: true,
              ),
            );
          } catch (_) {
            // Best-effort cleanup for local integration data.
          }
        }
        final eventTypeId = createdEventTypeId;
        if (eventTypeId != null && eventTypeId.trim().isNotEmpty) {
          try {
            await eventsRepository.deleteEventType(
              TenantAdminEventsRepoString.fromRaw(
                eventTypeId,
                isRequired: true,
              ),
            );
          } catch (_) {
            // Best-effort cleanup for local integration data.
          }
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

TenantAdminProfileTypeCapabilities _locationCapabilities({
  required String policy,
  required bool physicalHost,
}) {
  return tenantAdminProfileTypeCapabilitiesFromRaw(
    <String, TenantAdminProfileTypeCapabilityValue>{
      'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
        value: policy,
      ),
      'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
        value: false,
      ),
      'is_physical_host_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
        value: physicalHost,
      ),
      'is_reference_location_enabled':
          tenantAdminProfileTypeCapabilityValueFromRaw(value: false),
    },
  );
}

TenantAdminAccountsRepositoryContractPrimString _accountText(String value) {
  return TenantAdminAccountsRepositoryContractPrimString.fromRaw(
    value,
    isRequired: true,
  );
}

TenantAdminAccountProfilesRepoInt? _profileRevision(
  TenantAdminAccountProfile profile,
) {
  final revision = profile.aggregateRevision;
  return revision == null
      ? null
      : tenantAdminAccountProfilesRepoInt(revision, defaultValue: revision);
}

TenantAdminLocation _location(double latitude, double longitude) {
  return tenantAdminLocationFromRaw(latitude: latitude, longitude: longitude);
}

TenantAdminEventDraft _eventDraft({
  required String unique,
  required TenantAdminEventType eventType,
  String? placeRefId,
  bool online = false,
  TenantAdminEventOccurrence? existingOccurrence,
}) {
  return TenantAdminEventDraft(
    titleValue: tenantAdminRequiredText('Location Flow Event $unique'),
    contentValue: tenantAdminOptionalText('Location policy device proof'),
    type: eventType,
    occurrences: <TenantAdminEventOccurrence>[
      TenantAdminEventOccurrence(
        dateTimeStartValue:
            existingOccurrence?.dateTimeStartValue ??
            tenantAdminDateTime(
              DateTime.now().toUtc().add(const Duration(days: 30)),
            ),
        dateTimeEndValue: existingOccurrence?.dateTimeEndValue,
        occurrenceIdValue: existingOccurrence?.occurrenceIdValue,
        occurrenceSlugValue: existingOccurrence?.occurrenceSlugValue,
      ),
    ],
    publication: TenantAdminEventPublication(
      statusValue: tenantAdminRequiredText('draft'),
    ),
    location: TenantAdminEventLocation(
      modeValue: tenantAdminRequiredText(online ? 'online' : 'physical'),
      online: online
          ? TenantAdminEventOnlineLocation(
              urlValue: tenantAdminRequiredText(
                'https://example.com/location-flow-$unique',
              ),
            )
          : null,
    ),
    placeRef: placeRefId == null
        ? null
        : TenantAdminEventPlaceRef(
            typeValue: tenantAdminRequiredText('account_profile'),
            idValue: tenantAdminRequiredText(placeRefId),
          ),
  );
}

Future<void> _cleanupAccounts({
  required TenantAdminAccountsRepository accountsRepository,
  required List<String> accountSlugs,
}) async {
  for (final slug in accountSlugs.reversed) {
    final value = _accountText(slug);
    try {
      await accountsRepository.deleteAccount(value);
    } catch (_) {
      // Best-effort cleanup for local integration data.
    }
    try {
      await accountsRepository.forceDeleteAccount(value);
    } catch (_) {
      // Best-effort cleanup for local integration data.
    }
  }
}

String _requireDefine(String key, String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    fail('Missing --dart-define=$key for integration test execution.');
  }
  return normalized;
}

String _normalizeHost(String raw) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(
    trimmed.contains('://') ? trimmed : 'https://$trimmed',
  );
  if (uri == null || uri.host.trim().isEmpty) {
    fail('Invalid tenant host value: "$raw"');
  }
  return uri.host.trim().toLowerCase();
}

String _normalizeOrigin(String raw) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(
    trimmed.contains('://') ? trimmed : 'https://$trimmed',
  );
  if (uri == null || uri.host.trim().isEmpty) {
    fail('Invalid landlord origin value: "$raw"');
  }
  return uri.replace(path: '', query: null, fragment: null).toString();
}

String _normalizeScopeDomain(String raw) {
  final trimmed = raw.trim();
  final hasExplicitScheme = trimmed.contains('://');
  final uri = Uri.tryParse(hasExplicitScheme ? trimmed : 'https://$trimmed');
  if (uri == null || uri.host.trim().isEmpty) {
    fail('Invalid tenant admin route domain: "$raw"');
  }
  if (!hasExplicitScheme) {
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
  ).toString();
}

Dio _integrationDio({required int loopbackPort, BaseOptions? options}) {
  final dio = Dio(options);
  if (loopbackPort <= 0) {
    return dio;
  }
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.connectionFactory = (uri, proxyHost, proxyPort) {
        return Socket.startConnect(InternetAddress.loopbackIPv4, loopbackPort);
      };
      return client;
    },
  );
  return dio;
}

LandlordTenantOption _resolveTenantByDomain(
  List<LandlordTenantOption> tenants,
  String expectedHost,
) {
  for (final tenant in tenants) {
    if (_normalizeHost(tenant.mainDomain) == expectedHost) {
      return tenant;
    }
  }
  fail(
    'Tenant "$expectedHost" not found in landlord listing. '
    'Available: ${tenants.map((tenant) => tenant.mainDomain).join(', ')}',
  );
}

TenantAdminProfileTypeDefinition _locationProfileType() {
  final definitions = <TenantAdminProfileTypeCapabilityDefinition>[
    tenantAdminProfileTypeCapabilityDefinitionFromRaw(
      key: 'location_policy',
      domain: 'location',
      valueType: 'enum',
      defaultValue: 'disabled',
      failClosedValue: 'disabled',
      allowedValues: <String>['disabled', 'optional', 'required'],
      parameters: <TenantAdminProfileTypeCapabilityParameterDefinition>[],
      resources: <TenantAdminProfileTypeCapabilityResource>[],
    ),
    tenantAdminProfileTypeCapabilityDefinitionFromRaw(
      key: 'is_map_poi_enabled',
      domain: 'location',
      valueType: 'boolean',
      defaultValue: false,
      failClosedValue: false,
      allowedValues: <String>[],
      parameters: <TenantAdminProfileTypeCapabilityParameterDefinition>[],
      resources: <TenantAdminProfileTypeCapabilityResource>[],
    ),
    tenantAdminProfileTypeCapabilityDefinitionFromRaw(
      key: 'is_physical_host_enabled',
      domain: 'location',
      valueType: 'boolean',
      defaultValue: false,
      failClosedValue: false,
      allowedValues: <String>[],
      parameters: <TenantAdminProfileTypeCapabilityParameterDefinition>[],
      resources: <TenantAdminProfileTypeCapabilityResource>[],
    ),
    tenantAdminProfileTypeCapabilityDefinitionFromRaw(
      key: 'is_reference_location_enabled',
      domain: 'location',
      valueType: 'boolean',
      defaultValue: false,
      failClosedValue: false,
      allowedValues: <String>[],
      parameters: <TenantAdminProfileTypeCapabilityParameterDefinition>[],
      resources: <TenantAdminProfileTypeCapabilityResource>[],
    ),
  ];

  return tenantAdminProfileTypeDefinitionFromRaw(
    type: 'venue',
    label: 'Venue',
    pluralLabel: 'Venues',
    allowedTaxonomies: const <String>[],
    capabilityRevision: 7,
    capabilities: tenantAdminProfileTypeCapabilitiesFromRaw({
      'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
        value: 'disabled',
      ),
      'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
        value: false,
      ),
      'is_physical_host_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
        value: false,
      ),
      'is_reference_location_enabled':
          tenantAdminProfileTypeCapabilityValueFromRaw(value: false),
    }),
    capabilityDefinitions: definitions,
    visual: TenantAdminPoiVisual.icon(
      iconValue: TenantAdminRequiredTextValue()..parse('place'),
      colorValue: TenantAdminHexColorValue()..parse('#0F766E'),
    ),
  );
}

class _RecordingProfileTypesController
    extends TenantAdminProfileTypesController {
  _RecordingProfileTypesController() : super(repository: _Repository());

  int submitCalls = 0;
  int? expectedCapabilityRevision;
  TenantAdminProfileTypeCapabilities? savedCapabilities;

  @override
  Future<void> loadAvailableTaxonomies() async {}

  @override
  Future<void> hydrateFormDefinition(String type) async {}

  @override
  Future<void> submitUpdateType({
    required String type,
    String? newType,
    String? label,
    String? pluralLabel,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
    int? expectedCapabilityRevision,
    TenantAdminPoiVisual? visual,
    TenantAdminMediaUpload? typeAssetUpload,
    bool? removeTypeAsset,
    bool includeVisual = false,
  }) async {
    submitCalls += 1;
    this.expectedCapabilityRevision = expectedCapabilityRevision;
    savedCapabilities = capabilities;
  }
}

class _Repository extends TenantAdminAccountProfilesRepositoryContract
    with TenantAdminProfileTypesPaginationMixin {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
