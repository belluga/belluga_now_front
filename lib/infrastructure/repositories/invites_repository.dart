import 'dart:convert';

import 'package:belluga_now/application/invites/invite_contact_import_hashes.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_account_profile_ids.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_accepted_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_attendance_policy_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_cooldowns_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_credited_acceptance_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_decline_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_declined_at_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_event_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_has_other_pending_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_materialization_status_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_message_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_occurrence_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_rate_limits_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_share_code_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_name_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_match_cache_dto.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_backend_requests.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/invites_backend/laravel_invites_backend.dart';
import 'package:belluga_now/infrastructure/repositories/push/push_payload_upsert_mixin.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class InvitesRepository extends InvitesRepositoryContract
    with PushPayloadUpsertMixin<InviteModel>, PushInvitePayloadMixin
    implements PushInvitePayloadAware {
  static const int _maxContactImportItemsPerRequest = 500;
  static const Duration _contactImportCacheTtl = Duration(hours: 12);
  static const String _tenantIdStorageKey = 'tenant_id';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  InvitesRepository({
    InvitesBackendContract? backend,
    FriendsRepositoryContract? friendsRepository,
    InviteContactImportCacheContract? contactImportCache,
    DateTime Function()? now,
    Future<String?> Function()? currentUserIdProvider,
    Future<String?> Function()? tenantCacheScopeProvider,
    Future<String?> Function()? persistedTenantCacheScopeProvider,
    UserEventsRepositoryContract Function()? userEventsRepositoryResolver,
  })  : _backend = backend ?? LaravelInvitesBackend(),
        _contactImportCache = contactImportCache ?? InviteContactImportCache(),
        _now = now ?? DateTime.now,
        _currentUserIdProvider = currentUserIdProvider,
        _tenantCacheScopeProvider = tenantCacheScopeProvider,
        _persistedTenantCacheScopeProvider = persistedTenantCacheScopeProvider,
        _userEventsRepositoryResolver = userEventsRepositoryResolver;

  final InvitesBackendContract _backend;
  final InviteContactImportCacheContract _contactImportCache;
  final DateTime Function() _now;
  final Future<String?> Function()? _currentUserIdProvider;
  final Future<String?> Function()? _tenantCacheScopeProvider;
  final Future<String?> Function()? _persistedTenantCacheScopeProvider;
  final UserEventsRepositoryContract Function()? _userEventsRepositoryResolver;
  final InvitesResponseDecoder _responseDecoder =
      const InvitesResponseDecoder();
  UserEventsRepositoryContract? _userEventsRepository;

  UserEventsRepositoryContract? get _resolvedUserEventsRepository {
    if (_userEventsRepository != null) {
      return _userEventsRepository;
    }
    final resolver = _userEventsRepositoryResolver;
    if (resolver != null) {
      _userEventsRepository = resolver.call();
      return _userEventsRepository;
    }
    if (!GetIt.I.isRegistered<UserEventsRepositoryContract>()) {
      return null;
    }
    _userEventsRepository = GetIt.I.get<UserEventsRepositoryContract>();
    return _userEventsRepository;
  }

  @override
  Future<List<InviteContactMatch>?> hydrateImportedContactMatchesFromCache(
    InviteContacts contacts,
  ) async {
    final snapshot = await _resolveFreshImportedContactMatchSnapshot(contacts);
    final matches = snapshot?.matches;
    if (matches == null) {
      return null;
    }
    importedContactMatchesStreamValue.addValue(matches);
    return matches;
  }

  @override
  Future<List<InviteModel>> fetchInvites(
      {InvitesRepositoryContractPrimInt? page,
      InvitesRepositoryContractPrimInt? pageSize}) async {
    final resolvedPage = page ??
        invitesRepoInt(
          1,
          defaultValue: 1,
          isRequired: true,
        );
    final resolvedPageSize = pageSize ??
        invitesRepoInt(
          20,
          defaultValue: 20,
          isRequired: true,
        );
    final response = await _backend.fetchInvites(
      page: resolvedPage.value,
      pageSize: resolvedPageSize.value,
    );
    final invitesRaw = response['invites'];
    final invites = _responseDecoder
        .decodeInviteDtos(invitesRaw)
        .map((dto) => dto.toDomain())
        .toList(growable: false);

    if (resolvedPage.value == 1) {
      pendingInvitesStreamValue.addValue(invites);
    }

    return invites;
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    final response = await _backend.fetchSettings();
    final settings = InviteRuntimeSettings(
      tenantIdValue:
          _buildTenantIdValueOrNull(_stringOrNull(response['tenant_id'])),
      limitValues: InviteRateLimitsValue(_parseIntMap(response['limits'])),
      cooldownValues: InviteCooldownsValue(_parseIntMap(response['cooldowns'])),
      overQuotaMessageValue: _buildInviteMessageValueOrNull(
          _stringOrNull(response['over_quota_message'])),
    );
    settingsStreamValue.addValue(settings);
    return settings;
  }

  @override
  Future<InviteAcceptResult> acceptInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    final response = await _backend.acceptInvite(inviteId.value);
    await fetchInvites();
    final result = _decodeAcceptResult(response);
    if (result.isAccepted) {
      await _resolvedUserEventsRepository?.refreshConfirmedOccurrenceIds();
    }
    return result;
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    final response = await _backend.acceptShareCode(code.value);
    clearShareCodeSessionContext(code: code);
    await fetchInvites();
    final result = _decodeAcceptResult(response);
    if (result.isAccepted) {
      await _resolvedUserEventsRepository?.refreshConfirmedOccurrenceIds();
    }
    return result;
  }

  InviteAcceptResult _decodeAcceptResult(Object? response) =>
      _responseDecoder.decodeAcceptResult(response);

  @override
  Future<InviteDeclineResult> declineInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    final response = await _backend.declineInvite(inviteId.value);
    await fetchInvites();
    return InviteDeclineResult(
      inviteIdValue: _buildInviteIdValue(_stringOrEmpty(response['invite_id'])),
      statusValue: InviteDeclineStatusValue(_stringOrEmpty(response['status'])),
      groupHasOtherPendingValue: InviteHasOtherPendingValue(
          response['group_has_other_pending'] == true),
      declinedAtValue:
          InviteDeclinedAtValue(_parseDateTime(response['declined_at'])),
    );
  }

  @override
  Future<InviteMaterializeResult> materializeShareCode(
      InvitesRepositoryContractPrimString code) async {
    final response = await _backend.materializeShareCode(code.value);
    return InviteMaterializeResult(
      inviteIdValue: _buildInviteIdValue(_stringOrEmpty(response['invite_id'])),
      statusValue: _buildMaterializationStatusValue(
        _stringOrEmpty(response['status']),
      ),
      creditedAcceptanceValue: _buildCreditedAcceptanceValue(
        response['credited_acceptance'] == true,
      ),
      attendancePolicyValue: _buildAttendancePolicyValue(
        _resolveAttendancePolicy(response['attendance_policy']),
      ),
      acceptedAtValue: _buildAcceptedAtValue(
        _parseDateTime(response['accepted_at']),
      ),
    );
  }

  @override
  Future<InviteModel?> previewShareCode(
      InvitesRepositoryContractPrimString code) async {
    final response = await _backend.fetchShareCodePreview(code.value);
    final inviteRaw = response['invite'];
    final decoded = _responseDecoder.decodeRequiredInviteDto(
      inviteRaw,
      context: 'invite share preview',
    );
    return decoded.toDomain();
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    final snapshot = await _resolveFreshImportedContactMatchSnapshot(contacts);
    if (snapshot == null) {
      return const <InviteContactMatch>[];
    }

    if (!contacts.forceImport && snapshot.isFresh) {
      importedContactMatchesStreamValue.addValue(snapshot.matches);
      return snapshot.matches;
    }

    final matchesByProfileId = <String, InviteContactMatch>{};
    for (final chunk in _chunkContactImportItems(snapshot.importItems)) {
      final response = await _backend.importContacts(
        InviteContactImportRequest(contacts: chunk),
      );
      final matches =
          _responseDecoder.decodeContactMatches(response['matches']);
      for (final match in matches) {
        matchesByProfileId.putIfAbsent(
          match.receiverAccountProfileId,
          () => match,
        );
      }
    }

    await _contactImportCache.write(
      snapshot.cacheKey,
      InviteContactImportCacheEntry(
        signature: snapshot.signature,
        importedAt: _now(),
        matches: matchesByProfileId.values
            .map(InviteContactMatchCacheDto.fromDomain)
            .toList(growable: false),
      ),
    );

    final matches = matchesByProfileId.values.toList(growable: false);
    importedContactMatchesStreamValue.addValue(matches);
    return matches;
  }

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() async {
    final response = await _backend.fetchInviteableContacts();
    final recipients =
        _responseDecoder.decodeInviteableRecipients(response['items']);
    inviteableRecipientsStreamValue.addValue(recipients);
    return recipients;
  }

  @override
  Future<List<InviteContactGroup>> fetchContactGroups() async {
    final response = await _backend.fetchContactGroups();
    return _responseDecoder.decodeContactGroups(response['data']);
  }

  @override
  Future<InviteContactGroup?> createContactGroup({
    required InviteContactGroupNameValue nameValue,
    required InviteAccountProfileIds recipientAccountProfileIds,
  }) async {
    final response = await _backend.createContactGroup(
      name: nameValue.value,
      recipientAccountProfileIds:
          recipientAccountProfileIds.toList(growable: false),
    );
    return _responseDecoder.decodeContactGroup(response['data'] ?? response);
  }

  @override
  Future<InviteContactGroup?> updateContactGroup({
    required InviteContactGroupIdValue groupIdValue,
    InviteContactGroupNameValue? nameValue,
    InviteAccountProfileIds? recipientAccountProfileIds,
  }) async {
    final response = await _backend.updateContactGroup(
      groupId: groupIdValue.value,
      name: nameValue?.value,
      recipientAccountProfileIds:
          recipientAccountProfileIds?.toList(growable: false),
    );
    return _responseDecoder.decodeContactGroup(response['data'] ?? response);
  }

  @override
  Future<void> deleteContactGroup(
      InviteContactGroupIdValue groupIdValue) async {
    await _backend.deleteContactGroup(groupIdValue.value);
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    final normalizedOccurrenceId = occurrenceId.value.trim();
    if (normalizedOccurrenceId.isEmpty) {
      throw ArgumentError.value(
        occurrenceId.value,
        'occurrenceId',
        'Share-code invite targets require an occurrence identity.',
      );
    }
    final normalizedAccountProfileId = accountProfileId?.value.trim();
    final response = await _backend.createShareCode(
      InviteShareCodeCreateRequest(
        targetRef: InviteTargetRefRequest(
          eventId: eventId.value,
          occurrenceId: normalizedOccurrenceId,
        ),
        accountProfileId: normalizedAccountProfileId,
      ),
    );

    final targetRef = _responseDecoder.decodeShareCodeTargetRef(
      response['target_ref'],
      fallbackEventId: eventId.value,
    );

    return InviteShareCodeResult(
      codeValue: InviteShareCodeValue(_stringOrEmpty(response['code'])),
      eventIdValue: _buildInviteEventIdValue(targetRef.eventId),
      occurrenceIdValue: _buildInviteOccurrenceIdValue(targetRef.occurrenceId),
    );
  }

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {
    if (recipients.isEmpty) {
      return;
    }

    final normalizedOccurrenceId = occurrenceId.value.trim();
    if (normalizedOccurrenceId.isEmpty) {
      throw ArgumentError.value(
        occurrenceId.value,
        'occurrenceId',
        'Direct invite targets require an occurrence identity.',
      );
    }
    final normalizedMessage = message?.value.trim();
    final recipientPayloads = recipients.items
        .map((recipient) => recipient.accountProfileId.trim())
        .where((accountProfileId) => accountProfileId.isNotEmpty)
        .map((accountProfileId) => InviteSendRecipientRequest(
              receiverAccountProfileId: accountProfileId,
            ))
        .toList(growable: false);
    if (recipientPayloads.isEmpty) {
      return;
    }

    final response = await _backend.sendInvites(
      InviteSendRequest(
        targetRef: InviteTargetRefRequest(
          eventId: eventId.value,
          occurrenceId: normalizedOccurrenceId,
        ),
        recipients: recipientPayloads,
        message: normalizedMessage,
      ),
    );

    final acknowledgedRecipientIds = <String>{
      ..._parseRecipientIds(response['created']),
      ..._parseRecipientIds(response['already_invited']),
    };

    if (acknowledgedRecipientIds.isEmpty) {
      return;
    }

    final currentByOccurrence = sentInvitesByOccurrenceStreamValue.value;
    final occurrenceKey = invitesRepoString(
      normalizedOccurrenceId,
      defaultValue: '',
      isRequired: true,
    );
    final existing = List<SentInviteStatus>.from(
      currentByOccurrence[occurrenceKey] ?? const [],
    );
    final existingByRecipient = <String, SentInviteStatus>{
      for (final invite in existing) invite.friend.id: invite,
    };
    final now = DateTime.now();

    for (final recipient in recipients.items) {
      final accountProfileId = recipient.accountProfileId.trim();
      final acknowledged = acknowledgedRecipientIds.contains(recipient.id) ||
          (accountProfileId.isNotEmpty &&
              acknowledgedRecipientIds.contains(accountProfileId));
      if (!acknowledged) {
        continue;
      }
      existingByRecipient[recipient.id] = SentInviteStatus(
        friend: recipient,
        status: InviteStatus.pending,
        sentAtValue: existingByRecipient[recipient.id]?.sentAtValue ??
            (DateTimeValue()..parse(now.toIso8601String())),
        respondedAtValue: existingByRecipient[recipient.id]?.respondedAtValue,
      );
    }

    sentInvitesByOccurrenceStreamValue.addValue({
      ...currentByOccurrence,
      occurrenceKey: existingByRecipient.values.toList(growable: false),
    });
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
      InvitesRepositoryContractPrimString occurrenceId) async {
    return List<SentInviteStatus>.from(
      sentInvitesByOccurrenceStreamValue.value[occurrenceId] ??
          const <SentInviteStatus>[],
      growable: false,
    );
  }

  @override
  void applyInvitePushPayload(Object? payload) {
    final current = pendingInvitesStreamValue.value;
    final next = mergeInvitePayload(current: current, payload: payload);
    if (identical(current, next)) {
      return;
    }
    pendingInvitesStreamValue.addValue(next);
  }

  List<InviteContactImportItemRequest> _buildContactImportItems(
    List<ContactModel> contacts, {
    required String? regionCode,
  }) {
    final seen = <String>{};
    final items = <InviteContactImportItemRequest>[];

    for (final contact in contacts) {
      for (final email in contact.emails) {
        final normalized = email.value.trim().toLowerCase();
        if (normalized.isEmpty) {
          continue;
        }
        final hash = InviteContactImportHashes.contactHashes(
          ContactModel(
            idValue: contact.idValue,
            displayNameValue: contact.displayNameValue,
            emailValues: [email],
          ),
          regionCode: regionCode,
        ).single;
        final signature = 'email::$hash';
        if (!seen.add(signature)) {
          continue;
        }
        items.add(InviteContactImportItemRequest(type: 'email', hash: hash));
      }

      for (final phone in contact.phones) {
        final phoneOnlyContact = ContactModel(
          idValue: contact.idValue,
          displayNameValue: contact.displayNameValue,
          phoneValues: [phone],
        );
        for (final hash in InviteContactImportHashes.contactHashes(
          phoneOnlyContact,
          regionCode: regionCode,
        )) {
          final signature = 'phone::$hash';
          if (!seen.add(signature)) {
            continue;
          }
          items.add(InviteContactImportItemRequest(type: 'phone', hash: hash));
        }
      }
    }

    return items;
  }

  List<List<InviteContactImportItemRequest>> _chunkContactImportItems(
    List<InviteContactImportItemRequest> items,
  ) {
    final chunks = <List<InviteContactImportItemRequest>>[];
    for (var start = 0; start < items.length;) {
      final end = start + _maxContactImportItemsPerRequest > items.length
          ? items.length
          : start + _maxContactImportItemsPerRequest;
      chunks.add(items.sublist(start, end));
      start = end;
    }
    return chunks;
  }

  Future<String> _contactImportCacheKey({
    required String? regionCode,
  }) async {
    final userId = await _currentUserId();
    final tenantScope = await _tenantCacheScope();
    return sha256
        .convert(
          utf8.encode([
            'tenant=${tenantScope ?? 'unknown'}',
            'user=${userId ?? 'anonymous'}',
            'region=${regionCode ?? ''}',
          ].join('|')),
        )
        .toString();
  }

  Future<String?> _tenantCacheScope() async {
    final provider = _tenantCacheScopeProvider;
    if (provider != null) {
      final scoped = _normalizeNullable(await provider());
      if (scoped != null) {
        return scoped;
      }
    }

    if (GetIt.I.isRegistered<AppData>()) {
      final liveTenantId =
          _normalizeNullable(GetIt.I.get<AppData>().tenantIdValue.value);
      if (liveTenantId != null) {
        return liveTenantId;
      }
    }

    final persistedProvider = _persistedTenantCacheScopeProvider;
    if (persistedProvider != null) {
      return _normalizeNullable(await persistedProvider());
    }

    String? persistedTenantId;
    try {
      persistedTenantId = await _storage.read(key: _tenantIdStorageKey);
    } on MissingPluginException {
      persistedTenantId = null;
    } on PlatformException {
      persistedTenantId = null;
    }

    return _normalizeNullable(persistedTenantId);
  }

  Future<String?> _currentUserId() async {
    final provider = _currentUserIdProvider;
    if (provider != null) {
      return _normalizeNullable(await provider());
    }

    if (!GetIt.I.isRegistered<AuthRepositoryContract>()) {
      return null;
    }

    return _normalizeNullable(
      await GetIt.I.get<AuthRepositoryContract>().getUserId(),
    );
  }

  String _contactImportSignature(
    List<InviteContactImportItemRequest> items,
  ) {
    final normalized = items
        .map((item) => '${item.type}:${item.hash}')
        .toList(growable: false)
      ..sort();
    return sha256.convert(utf8.encode(normalized.join('|'))).toString();
  }

  String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  List<String> _parseRecipientIds(Object? raw) {
    return _responseDecoder.decodeRecipientIds(raw);
  }

  Map<String, int> _parseIntMap(Object? raw) {
    return _responseDecoder.decodeIntMap(raw);
  }

  DateTime? _parseDateTime(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String _stringOrEmpty(Object? raw) => raw?.toString() ?? '';

  String? _stringOrNull(Object? raw) {
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String _resolveAttendancePolicy(Object? rawValue) {
    final value = _stringOrEmpty(rawValue);
    if (value.isEmpty) {
      return 'free_confirmation_only';
    }
    return value;
  }

  InviteIdValue _buildInviteIdValue(String value) {
    final inviteIdValue = InviteIdValue()..parse(value);
    return inviteIdValue;
  }

  InviteMaterializationStatusValue _buildMaterializationStatusValue(
    String value,
  ) {
    final statusValue = InviteMaterializationStatusValue()..parse(value);
    return statusValue;
  }

  InviteCreditedAcceptanceValue _buildCreditedAcceptanceValue(bool value) {
    final creditedValue = InviteCreditedAcceptanceValue()
      ..parse(value.toString());
    return creditedValue;
  }

  InviteAttendancePolicyValue _buildAttendancePolicyValue(String value) {
    final attendancePolicyValue = InviteAttendancePolicyValue()..parse(value);
    return attendancePolicyValue;
  }

  InviteAcceptedAtValue _buildAcceptedAtValue(DateTime? value) {
    final acceptedAtValue = InviteAcceptedAtValue()
      ..parse(value?.toIso8601String());
    return acceptedAtValue;
  }

  TenantIdValue? _buildTenantIdValueOrNull(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final tenantIdValue = TenantIdValue()..parse(value);
    return tenantIdValue;
  }

  InviteMessageValue? _buildInviteMessageValueOrNull(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final messageValue = InviteMessageValue()..parse(value);
    return messageValue;
  }

  InviteEventIdValue _buildInviteEventIdValue(String value) {
    final eventIdValue = InviteEventIdValue()..parse(value);
    return eventIdValue;
  }

  InviteOccurrenceIdValue _buildInviteOccurrenceIdValue(String value) {
    final occurrenceIdValue = InviteOccurrenceIdValue()..parse(value);
    return occurrenceIdValue;
  }

  Future<_ImportedContactMatchCacheSnapshot?>
      _resolveFreshImportedContactMatchSnapshot(
    InviteContacts contacts,
  ) async {
    final importItems = _buildContactImportItems(
      contacts.items,
      regionCode: contacts.regionCode,
    );
    if (importItems.isEmpty) {
      return null;
    }

    final cacheKey = await _contactImportCacheKey(
      regionCode: contacts.regionCode,
    );
    final signature = _contactImportSignature(importItems);
    final cachedImport = await _contactImportCache.read(cacheKey);
    final isFresh = !contacts.forceImport &&
        cachedImport != null &&
        cachedImport.signature == signature &&
        cachedImport.isFresh(_now(), _contactImportCacheTtl);

    return _ImportedContactMatchCacheSnapshot(
      cacheKey: cacheKey,
      signature: signature,
      importItems: importItems,
      isFresh: isFresh,
      matches: isFresh
          ? _cachedImportedMatches(cachedImport)
          : const <InviteContactMatch>[],
    );
  }

  List<InviteContactMatch> _cachedImportedMatches(
    InviteContactImportCacheEntry? cachedImport,
  ) {
    if (cachedImport != null && cachedImport.matches.isNotEmpty) {
      return cachedImport.matches.map((match) => match.toDomain()).toList(
            growable: false,
          );
    }

    final inMemory = importedContactMatchesStreamValue.value;
    if (inMemory != null) {
      return inMemory;
    }

    if (cachedImport == null) {
      return const <InviteContactMatch>[];
    }
    return const <InviteContactMatch>[];
  }
}

class _ImportedContactMatchCacheSnapshot {
  const _ImportedContactMatchCacheSnapshot({
    required this.cacheKey,
    required this.signature,
    required this.importItems,
    required this.isFresh,
    required this.matches,
  });

  final String cacheKey;
  final String signature;
  final List<InviteContactImportItemRequest> importItems;
  final bool isFresh;
  final List<InviteContactMatch> matches;
}
