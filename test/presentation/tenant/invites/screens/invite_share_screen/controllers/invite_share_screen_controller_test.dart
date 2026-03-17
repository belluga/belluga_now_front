import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

class _FakeContactsRepository implements ContactsRepositoryContract {
  _FakeContactsRepository({
    this.throwOnRequestPermission = false,
    this.contacts = const <ContactModel>[],
  });

  bool permissionGranted = true;
  bool throwOnRequestPermission;
  bool throwOnGetContacts = false;
  List<ContactModel> contacts;

  @override
  Future<bool> requestPermission() async {
    if (throwOnRequestPermission) {
      throw Exception('request permission failed');
    }
    return permissionGranted;
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    if (throwOnGetContacts) {
      throw Exception('get contacts failed');
    }
    return contacts;
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  bool throwOnImportContacts = false;

  @override
  Future<List<InviteModel>> fetchInvites(
          {int page = 1, int pageSize = 20}) async =>
      const [];

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      const InviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async =>
      buildInviteAcceptResult(
        inviteId: inviteId,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async =>
      InviteDeclineResult(
        inviteId: inviteId,
        status: 'declined',
        groupHasOtherPending: false,
      );

  @override
  Future<InviteAcceptResult> acceptShareCode(String code) async =>
      buildInviteAcceptResult(
        inviteId: code,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.openAppToContinue,
        supersededInviteIds: const [],
      );

  @override
  Future<List<InviteContactMatch>> importContacts(
      List<ContactModel> contacts) async {
    if (throwOnImportContacts) {
      throw Exception('import contacts failed');
    }

    if (contacts.isEmpty) {
      return const <InviteContactMatch>[];
    }

    return const <InviteContactMatch>[
      InviteContactMatch(
        contactHash: 'hash-1',
        type: 'phone',
        userId: 'user-1',
        displayName: 'Matched Contact',
        avatarUrl: null,
      ),
    ];
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  }) async =>
      InviteShareCodeResult(
        code: 'SHARE-CODE',
        eventId: eventId,
        occurrenceId: occurrenceId,
      );

  @override
  Future<void> sendInvites(
    String eventSlug,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    String eventSlug,
  ) async =>
      const <SentInviteStatus>[];
}

InviteModel _buildInvite() {
  return InviteModel.fromPrimitives(
    id: 'invite-1',
    eventId: 'event-1',
    eventName: 'Evento Teste',
    eventDateTime: DateTime(2026, 3, 13, 20),
    eventImageUrl: 'https://example.com/event.jpg',
    location: 'Guarapari',
    hostName: 'Host',
    message: 'Bora?',
    tags: const ['music'],
    inviterName: 'Amigo',
  );
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
      {
        'type': 'personal',
        'label': 'Personal',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
    ],
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return AppData.fromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

void main() {
  test(
    'init does not keep loading state when contact permission throws',
    () async {
      final contactsRepository = _FakeContactsRepository(
        throwOnRequestPermission: true,
      );
      final controller = InviteShareScreenController(
        invitesRepository: _FakeInvitesRepository(),
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(controller.contactsPermissionGranted.value, isFalse);
      expect(controller.friendsSuggestionsStreamValue.value, isEmpty);
      expect(controller.sentInvitesStreamValue.value, isEmpty);
      expect(controller.shareCodeStreamValue.value?.code, 'SHARE-CODE');

      await controller.onDispose();
    },
  );

  test(
    'init falls back to empty friend suggestions when import contacts fails',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: const <ContactModel>[
          ContactModel(
            id: 'contact-1',
            displayName: 'Contato 1',
            phones: <String>['+55 27 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..throwOnImportContacts = true;
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(controller.friendsSuggestionsStreamValue.value, isEmpty);
      expect(controller.sentInvitesStreamValue.value, isEmpty);
      expect(controller.shareCodeStreamValue.value?.code, 'SHARE-CODE');

      await controller.onDispose();
    },
  );
}
