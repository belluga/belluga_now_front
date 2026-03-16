import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('tenant without pending invites resolves tenant home stack', () async {
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: false),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.tenant),
      ),
    );

    await controller.initialize();

    expect(controller.initialRoute, isA<TenantHomeRoute>());
    expect(
      controller.initialRouteStack.map((route) => route.routeName).toList(),
      [TenantHomeRoute.name],
    );
  });

  test('tenant with pending invites stacks invite flow on top of home', () async {
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: true),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.tenant),
      ),
    );

    await controller.initialize();

    expect(controller.initialRoute, isA<InviteFlowRoute>());
    expect(
      controller.initialRouteStack.map((route) => route.routeName).toList(),
      [
        TenantHomeRoute.name,
        InviteFlowRoute.name,
      ],
    );
  });

  test('landlord ignores tenant invite flow and resolves landlord home', () async {
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: true),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.landlord),
      ),
    );

    await controller.initialize();

    expect(controller.initialRoute, isA<LandlordHomeRoute>());
    expect(
      controller.initialRouteStack.map((route) => route.routeName).toList(),
      [LandlordHomeRoute.name],
    );
  });
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({required this.hasPendingInvites});

  @override
  final bool hasPendingInvites;

  @override
  Future<void> init() async {
    pendingInvitesStreamValue.addValue(
      hasPendingInvites ? [_buildInvite()] : const [],
    );
  }

  @override
  Future<List<InviteModel>> fetchInvites({int page = 1, int pageSize = 20}) async {
    return hasPendingInvites ? [_buildInvite()] : const [];
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    return const InviteRuntimeSettings(
      tenantId: null,
      limits: {},
      cooldowns: {},
      overQuotaMessage: null,
    );
  }

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async {
    return InviteAcceptResult(
      inviteId: inviteId,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteAcceptResult> acceptShareCode(String code) async {
    return InviteAcceptResult(
      inviteId: code,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.openAppToContinue,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async {
    return InviteDeclineResult(
      inviteId: inviteId,
      status: 'declined',
      groupHasOtherPending: false,
    );
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  }) async {
    return InviteShareCodeResult(
      code: 'CODE123',
      eventId: eventId,
      occurrenceId: occurrenceId,
    );
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(String eventId) async {
    return const [];
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    List<ContactModel> contacts,
  ) async {
    return const [];
  }

  @override
  Future<void> sendInvites(
    String eventId,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {}
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository(this.appData);

  @override
  final AppData appData;

  @override
  StreamValue<double> get maxRadiusMetersStreamValue =>
      StreamValue<double>(defaultValue: 1000);

  @override
  double get maxRadiusMeters => 1000;

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(double meters) async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
}

InviteModel _buildInvite() {
  return InviteModel.fromPrimitives(
    id: 'invite-1',
    eventId: 'event-1',
    eventName: 'Evento',
    eventDateTime: DateTime(2026, 3, 15, 20),
    eventImageUrl: 'https://example.com/event.png',
    location: 'Centro',
    hostName: 'Host',
    message: 'Bora sim',
    tags: const ['show'],
    inviterName: 'Ana',
  );
}

AppData _buildAppData({
  required EnvironmentType environmentType,
}) {
  final platformType = PlatformTypeValue()..parse(AppType.web.name);
  final hostname = environmentType == EnvironmentType.landlord
      ? 'landlord.belluga.space'
      : 'guarappari.belluga.space';
  return AppData.fromInitialization(
    remoteData: {
      'name': 'Test',
      'type': environmentType.name,
      'main_domain': 'https://$hostname',
      'domains': ['https://$hostname'],
      'app_domains': const [],
      'theme_data_settings': {
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#E80D5D',
        'brightness_default': 'light',
      },
      'main_color': '#4FA0E3',
      'tenant_id': 'tenant-1',
      'telemetry': {'trackers': []},
    },
    localInfo: {
      'platformType': platformType,
      'hostname': hostname,
      'href': 'https://$hostname',
      'port': null,
      'device': 'test-device',
    },
  );
}
