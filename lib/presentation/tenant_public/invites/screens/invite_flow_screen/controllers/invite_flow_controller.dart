export 'invite_decision_result.dart';

import 'dart:async';

import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_decision_result.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InviteFlowScreenController with Disposable {
  InviteFlowScreenController({
    InvitesRepositoryContract? repository,
    UserEventsRepositoryContract? userEventsRepository,
    TelemetryRepositoryContract? telemetryRepository,
    CardStackSwiperController? cardStackSwiperController,
    AuthRepositoryContract? authRepository,
  })  : _repository = repository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>(),
        _authRepository = authRepository ??
            (GetIt.I.isRegistered<AuthRepositoryContract>()
                ? GetIt.I.get<AuthRepositoryContract>()
                : null),
        swiperController =
            cardStackSwiperController ?? CardStackSwiperController();

  final InvitesRepositoryContract _repository;
  final TelemetryRepositoryContract _telemetryRepository;
  final AuthRepositoryContract? _authRepository;

  final CardStackSwiperController swiperController;
  final _displayInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const <InviteModel>[]);
  final _pendingInvitesStreamValue =
      StreamValue<List<InviteModel>>(defaultValue: const <InviteModel>[]);

  final decisionsStreamValue =
      StreamValue<Map<String, InviteDecision>>(defaultValue: const {});
  StreamValue<List<InviteModel>> get displayInvitesStreamValue =>
      _displayInvitesStreamValue;
  final authRequiredForDecisionStreamValue =
      StreamValue<bool>(defaultValue: false);
  final initializedStreamValue = StreamValue<bool>(defaultValue: false);
  final redirectPathStreamValue = StreamValue<String?>(defaultValue: null);

  StreamValue<List<InviteModel>> get pendingInvitesStreamValue =>
      _pendingInvitesStreamValue;

  InviteModel? get currentInvite => displayInvitesStreamValue.value.isNotEmpty
      ? displayInvitesStreamValue.value.first
      : null;
  bool get hasPendingInvites => displayInvitesStreamValue.value.isNotEmpty;
  bool get requiresAuthenticationForDecision =>
      authRequiredForDecisionStreamValue.value;
  String? get redirectPath => redirectPathStreamValue.value;

  final Map<String, InviteDecision> _decisions = <String, InviteDecision>{};
  Map<String, InviteDecision> get decisions => Map.unmodifiable(_decisions);

  final confirmingPresenceStreamValue = StreamValue<bool>(defaultValue: false);
  final topCardIndexStreamValue = StreamValue<int>(defaultValue: 0);
  final loadedImagesStreamValue =
      StreamValue<Set<String>>(defaultValue: const {});
  final decisionResultStreamValue =
      StreamValue<InviteDecisionResult?>(defaultValue: null);
  final Set<String> _openedInviteIds = <String>{};
  Future<EventTrackerTimedEventHandle?>? _activeInviteTimedEventFuture;
  String? _activeInviteId;
  String? _activeMaterializedInviteId;
  StreamSubscription<List<InviteModel>>? _pendingInvitesSubscription;

  bool get _isAuthorized => _authRepository?.isAuthorized ?? true;

  Future<void> init({
    String? prioritizeInviteId,
    String? shareCode,
    String? redirectPath,
  }) async {
    initializedStreamValue.addValue(false);
    displayInvitesStreamValue.addValue(const <InviteModel>[]);
    _setRedirectPath(redirectPath);
    _activeMaterializedInviteId = null;
    final normalizedShareCode = shareCode?.trim() ?? '';

    if (kIsWeb) {
      // Web policy: keep invite landing preview-only and avoid mutation/materialization.
      authRequiredForDecisionStreamValue.addValue(false);
      _finishActiveInviteTimedEvent();
      final preview = await _fetchAnonymousPreviewInvites(normalizedShareCode);
      displayInvitesStreamValue.addValue(preview);
      _ensureTopIndexBounds(preview.length);
      initializedStreamValue.addValue(true);
      return;
    }

    if (!_isAuthorized) {
      // Allow anonymous invite acceptance (invert auth-first to anonymous-first)
      authRequiredForDecisionStreamValue.addValue(false);
      _finishActiveInviteTimedEvent();
      final preview = await _fetchAnonymousPreviewInvites(normalizedShareCode);
      displayInvitesStreamValue.addValue(preview);
      _ensureTopIndexBounds(preview.length);
      initializedStreamValue.addValue(true);
      return;
    }

    try {
      authRequiredForDecisionStreamValue.addValue(false);
      _ensureInviteTrackingSubscription();
      if (normalizedShareCode.isNotEmpty) {
        final materialized = await _materializeShareCode(normalizedShareCode);
        final materializedInviteId = materialized?.inviteId.trim() ?? '';
        if (materialized != null &&
            materialized.isPending &&
            materializedInviteId.isNotEmpty) {
          _activeMaterializedInviteId = materializedInviteId;
          await fetchPendingInvites();
          _prioritizeInvite(materializedInviteId);
        } else {
          pendingInvitesStreamValue.addValue(const <InviteModel>[]);
          displayInvitesStreamValue.addValue(const <InviteModel>[]);
          _ensureTopIndexBounds(0);
        }
      } else {
        await fetchPendingInvites();
        if (prioritizeInviteId != null && prioritizeInviteId.isNotEmpty) {
          _prioritizeInvite(prioritizeInviteId);
        }
        _syncDisplayInvitesWithPending();
      }
    } finally {
      initializedStreamValue.addValue(true);
    }
  }

  Future<void> trackWebLanding(String? shareCode) async {
    if (!kIsWeb) {
      return;
    }
    final normalizedCode = shareCode?.trim();
    final hasCode = normalizedCode != null && normalizedCode.isNotEmpty;
    await _telemetryRepository.logEvent(
      EventTrackerEvents.viewContent,
      eventName: telemetryRepoString('web_invite_landing_opened'),
      properties: telemetryRepoMap(<String, dynamic>{
        'store_channel': 'web',
        'has_code': hasCode,
      }),
    );
  }

  Future<InviteMaterializeResult?> _materializeShareCode(
      String shareCode) async {
    try {
      return await _repository.materializeShareCode(
        invitesRepoString(
          shareCode,
          defaultValue: '',
          isRequired: true,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void _setRedirectPath(String? redirectPath) {
    final normalized = redirectPath?.trim();
    if (normalized == null || normalized.isEmpty) {
      redirectPathStreamValue.addValue('/invite');
      return;
    }
    redirectPathStreamValue.addValue(normalized);
  }

  Future<List<InviteModel>> _fetchAnonymousPreviewInvites(
      String shareCode) async {
    final normalizedCode = shareCode.trim();
    if (normalizedCode.isEmpty) {
      _repository.clearShareCodePreview();
      return const <InviteModel>[];
    }

    try {
      await _repository.loadShareCodePreview(
        invitesRepoString(
          normalizedCode,
          defaultValue: '',
          isRequired: true,
        ),
      );
      final preview = _repository.shareCodePreviewInviteStreamValue.value;
      if (preview == null) {
        return const <InviteModel>[];
      }
      return <InviteModel>[preview];
    } catch (_) {
      _repository.clearShareCodePreview();
      return const <InviteModel>[];
    }
  }

  Future<void> fetchPendingInvites() async {
    try {
      await _repository.refreshPendingInvites();
      final invites =
          List<InviteModel>.from(_repository.pendingInvitesStreamValue.value);
      pendingInvitesStreamValue.addValue(
        invites,
      );
      _syncDisplayInvitesWithPending();
      _ensureTopIndexBounds(invites.length);
    } catch (_) {
      pendingInvitesStreamValue.addValue(const <InviteModel>[]);
      _syncDisplayInvitesWithPending();
      _ensureTopIndexBounds(0);
    }
  }

  void _syncDisplayInvitesWithPending() {
    if (authRequiredForDecisionStreamValue.value) {
      return;
    }
    displayInvitesStreamValue.addValue(
      List<InviteModel>.from(pendingInvitesStreamValue.value),
    );
  }

  void _prioritizeInvite(String inviteId) {
    final inviteIdValue = _inviteIdValue(inviteId);
    final invites = List<InviteModel>.from(pendingInvitesStreamValue.value);
    final index =
        invites.indexWhere((invite) => invite.containsInviteId(inviteIdValue));
    if (index < 0) {
      return;
    }

    final invite = invites.removeAt(index).prioritizeInviter(inviteIdValue);
    invites.insert(0, invite);
    pendingInvitesStreamValue.addValue(invites);
    _syncDisplayInvitesWithPending();
    _ensureTopIndexBounds(invites.length);
  }

  void removeInvite() {
    final pendingInvites =
        List<InviteModel>.from(pendingInvitesStreamValue.value);

    if (pendingInvites.isEmpty) {
      return;
    }

    pendingInvites.removeAt(0);
    pendingInvitesStreamValue.addValue(pendingInvites);
    _syncDisplayInvitesWithPending();
    _ensureTopIndexBounds(pendingInvites.length);
  }

  void addInvite(InviteModel invite) {
    final pendingInvites =
        List<InviteModel>.from(pendingInvitesStreamValue.value)..add(invite);

    pendingInvitesStreamValue.addValue(pendingInvites);
    _syncDisplayInvitesWithPending();
    _ensureTopIndexBounds(pendingInvites.length);
  }

  Future<InviteDecisionResult?> applyDecision(InviteDecision decision) async {
    final result = await _finalizeDecision(decision);
    if (decision != InviteDecision.accepted) {
      resetConfirmPresence();
    }
    return result;
  }

  Future<InviteDecisionResult?> applyDecisionForInvite(
    InviteDecision decision,
    String inviteId,
  ) async {
    final result = await _finalizeDecision(decision, inviteId: inviteId);
    if (decision != InviteDecision.accepted) {
      resetConfirmPresence();
    }
    return result;
  }

  Future<void> requestDecision(InviteDecision decision) async {
    final result = await applyDecision(decision);
    decisionResultStreamValue.addValue(result);
  }

  Future<void> requestDecisionForInvite(
    InviteDecision decision,
    String inviteId,
  ) async {
    final result = await applyDecisionForInvite(decision, inviteId);
    decisionResultStreamValue.addValue(result);
  }

  void clearDecisionResult() {
    decisionResultStreamValue.addValue(null);
  }

  Future<InviteDecisionResult?> _finalizeDecision(
    InviteDecision decision, {
    String? inviteId,
  }) async {
    // Allow decision even if not authorized (anonymous acceptance flow)
    if (authRequiredForDecisionStreamValue.value) {
      return null;
    }

    final invites = List<InviteModel>.from(displayInvitesStreamValue.value);
    final current = invites.isEmpty ? null : invites.first;
    if (current == null) {
      return null;
    }
    var resolvedInviteId = inviteId ?? current.primaryInviteId;
    if (resolvedInviteId == null || resolvedInviteId.isEmpty) {
      resolvedInviteId = await _resolveInviteIdForTarget(current);
    }
    final materializedInviteId = _activeMaterializedInviteId?.trim() ?? '';
    if ((resolvedInviteId == null || resolvedInviteId.isEmpty) &&
        materializedInviteId.isNotEmpty &&
        (current.id == materializedInviteId ||
            current.containsInviteId(_inviteIdValue(materializedInviteId)))) {
      resolvedInviteId = materializedInviteId;
    }

    if (resolvedInviteId == null || resolvedInviteId.isEmpty) {
      return null;
    }

    _finishActiveInviteTimedEvent(expectedInviteId: current.id);
    _decisions[current.id] = decision;
    decisionsStreamValue.addValue(Map.unmodifiable(_decisions));

    if (decision == InviteDecision.accepted) {
      final isAnonymousDecision = !_isAuthorized;
      final acceptedInviteId = resolvedInviteId;
      final result = await _repository.acceptInvite(
        invitesRepoString(
          resolvedInviteId,
          defaultValue: '',
          isRequired: true,
        ),
      );
      if (isAnonymousDecision) {
        unawaited(
          _trackAnonymousInviteAccepted(
            invite: current,
            inviteId: acceptedInviteId,
          ),
        );
      }
      final updatedInvites =
          List<InviteModel>.from(_repository.pendingInvitesStreamValue.value);
      pendingInvitesStreamValue.addValue(updatedInvites);
      _syncDisplayInvitesWithPending();
      _ensureTopIndexBounds(updatedInvites.length);
      final resolvedInviteIdValue = _inviteIdValue(resolvedInviteId);
      return InviteDecisionResult(
        invite: current.prioritizeInviter(resolvedInviteIdValue),
        queued: false,
        nextStep: result.nextStep,
      );
    }

    await _repository.declineInvite(
      invitesRepoString(
        resolvedInviteId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    final updatedInvites =
        List<InviteModel>.from(_repository.pendingInvitesStreamValue.value);
    pendingInvitesStreamValue.addValue(updatedInvites);
    _syncDisplayInvitesWithPending();
    _ensureTopIndexBounds(updatedInvites.length);
    return const InviteDecisionResult(invite: null, queued: false);
  }

  Future<String?> _resolveInviteIdForTarget(InviteModel reference) async {
    final fromCurrent = _findInviteIdForTarget(
      reference: reference,
      invites: pendingInvitesStreamValue.value,
    );
    if (fromCurrent != null && fromCurrent.isNotEmpty) {
      return fromCurrent;
    }

    await fetchPendingInvites();
    return _findInviteIdForTarget(
      reference: reference,
      invites: pendingInvitesStreamValue.value,
    );
  }

  String? _findInviteIdForTarget({
    required InviteModel reference,
    required List<InviteModel> invites,
  }) {
    for (final invite in invites) {
      final primaryInviteId = invite.primaryInviteId;
      if (primaryInviteId == null || primaryInviteId.isEmpty) {
        continue;
      }
      if (_matchesInviteTarget(reference, invite)) {
        return primaryInviteId;
      }
    }
    return null;
  }

  bool _matchesInviteTarget(InviteModel reference, InviteModel candidate) {
    if (reference.id == candidate.id) {
      return true;
    }
    if (reference.eventId != candidate.eventId) {
      return false;
    }
    final referenceOccurrence = reference.occurrenceId?.trim();
    final candidateOccurrence = candidate.occurrenceId?.trim();
    if ((referenceOccurrence ?? '').isEmpty &&
        (candidateOccurrence ?? '').isEmpty) {
      return true;
    }
    return referenceOccurrence == candidateOccurrence;
  }

  void rewindInvite(InviteModel invite) {
    addInvite(invite);

    _decisions.remove(invite.id);
    decisionsStreamValue.addValue(Map.unmodifiable(_decisions));
  }

  bool beginConfirmPresence() {
    if (confirmingPresenceStreamValue.value) {
      return false;
    }

    if (!hasPendingInvites) {
      return false;
    }

    confirmingPresenceStreamValue.addValue(true);
    return true;
  }

  void resetConfirmPresence() {
    confirmingPresenceStreamValue.addValue(false);
  }

  void updateTopCardIndex({
    required int previousIndex,
    required int? currentIndex,
    required int invitesLength,
  }) {
    if (invitesLength == 0) {
      topCardIndexStreamValue.addValue(0);
      return;
    }

    final nextIndex =
        (currentIndex ?? previousIndex).clamp(0, invitesLength - 1);
    if (nextIndex != topCardIndexStreamValue.value) {
      topCardIndexStreamValue.addValue(nextIndex);
    }
  }

  void _ensureTopIndexBounds(int invitesLength) {
    if (invitesLength <= 0) {
      if (topCardIndexStreamValue.value != 0) {
        topCardIndexStreamValue.addValue(0);
      }
      return;
    }

    final current = topCardIndexStreamValue.value;
    final clamped = current.clamp(0, invitesLength - 1);
    if (clamped != current) {
      topCardIndexStreamValue.addValue(clamped);
    }
  }

  bool isImageLoaded(String url) {
    return loadedImagesStreamValue.value.contains(url);
  }

  void markImageLoaded(String url) {
    final current = loadedImagesStreamValue.value;
    if (current.contains(url)) {
      return;
    }
    final next = Set<String>.from(current)..add(url);
    loadedImagesStreamValue.addValue(next);
  }

  void _ensureInviteTrackingSubscription() {
    if (_pendingInvitesSubscription != null) {
      return;
    }
    _pendingInvitesSubscription =
        _pendingInvitesStreamValue.stream.listen(_handleInviteStreamUpdate);
    _handleInviteStreamUpdate(pendingInvitesStreamValue.value);
  }

  void _handleInviteStreamUpdate(List<InviteModel> invites) {
    _syncDisplayInvitesWithPending();
    if (invites.isEmpty) {
      _finishActiveInviteTimedEvent();
      return;
    }
    unawaited(_trackInviteOpened(invites));
  }

  Future<void> _trackInviteOpened(List<InviteModel> invites) async {
    if (invites.isEmpty) return;
    final current = invites.first;
    if (_activeInviteId != null && _activeInviteId != current.id) {
      _finishActiveInviteTimedEvent();
    }
    if (_openedInviteIds.add(current.id)) {
      _activeInviteTimedEventFuture = _telemetryRepository.startTimedEvent(
        EventTrackerEvents.inviteOpened,
        eventName: telemetryRepoString('invite_opened'),
        properties: telemetryRepoMap(_buildInviteTelemetryProperties(current)),
      );
      _activeInviteId = current.id;
    }
  }

  Map<String, dynamic> _buildInviteTelemetryProperties(InviteModel invite) {
    final properties = <String, dynamic>{
      'event_id': invite.eventId,
      'source': 'invite_flow',
    };

    final inviterPrincipal = invite.inviterPrincipal;
    if (inviterPrincipal != null) {
      properties['inviter_kind'] = inviterPrincipal.type.name;
      properties['inviter_id'] = inviterPrincipal.id;
      if (inviterPrincipal.type == InviteInviterType.accountProfile) {
        properties['account_profile_id'] = inviterPrincipal.id;
      }
    }

    return properties;
  }

  Future<void> _trackAnonymousInviteAccepted({
    required InviteModel invite,
    required String inviteId,
  }) async {
    final properties = <String, dynamic>{
      'event_id': invite.eventId,
      'invite_id': inviteId,
      'source': 'invite_flow',
    };

    final shareCode = _extractShareCode(inviteId);
    if (shareCode != null) {
      properties['code'] = shareCode;
    }

    final inviterPrincipal = invite.inviterPrincipal;
    if (inviterPrincipal != null) {
      properties['inviter_kind'] = inviterPrincipal.type.name;
      properties['inviter_id'] = inviterPrincipal.id;
    }

    await _telemetryRepository.logEvent(
      EventTrackerEvents.buttonClick,
      eventName: telemetryRepoString('app_anonymous_invite_accepted'),
      properties: telemetryRepoMap(properties),
    );
  }

  InviteIdValue _inviteIdValue(String raw) {
    final value = InviteIdValue();
    value.parse(raw);
    return value;
  }

  String? _extractShareCode(String inviteId) {
    final normalized = inviteId.trim();
    const prefix = 'share:';
    if (!normalized.startsWith(prefix)) {
      return null;
    }
    final code = normalized.substring(prefix.length).trim();
    if (code.isEmpty) {
      return null;
    }
    return code;
  }

  void syncTopCardIndex(int invitesLength) {
    _ensureTopIndexBounds(invitesLength);
  }

  @override
  FutureOr<void> onDispose() {
    _pendingInvitesSubscription?.cancel();
    _pendingInvitesSubscription = null;
    _finishActiveInviteTimedEvent();
    decisionsStreamValue.dispose();
    _displayInvitesStreamValue.dispose();
    _pendingInvitesStreamValue.dispose();
    authRequiredForDecisionStreamValue.dispose();
    initializedStreamValue.dispose();
    redirectPathStreamValue.dispose();
    swiperController.dispose();
    confirmingPresenceStreamValue.dispose();
    topCardIndexStreamValue.dispose();
    loadedImagesStreamValue.dispose();
    decisionResultStreamValue.dispose();
  }

  void _finishActiveInviteTimedEvent({
    String? expectedInviteId,
  }) {
    final handleFuture = _activeInviteTimedEventFuture;
    if (handleFuture == null) {
      return;
    }
    if (expectedInviteId != null && _activeInviteId != expectedInviteId) {
      return;
    }
    _activeInviteTimedEventFuture = null;
    _activeInviteId = null;
    unawaited(handleFuture.then<void>((handle) async {
      if (handle != null) {
        await _telemetryRepository.finishTimedEvent(handle);
      }
    }));
  }
}
