import 'dart:async';

import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/push/invite_accepted_push_payload.dart';
import 'package:belluga_now/infrastructure/dal/dao/push/invite_push_payload_decoder.dart';
import 'package:belluga_now/infrastructure/repositories/push/push_payload_upsert_mixin.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class InvitePushRuntimeCoordinator {
  InvitePushRuntimeCoordinator({
    required Future<void> Function(String path) navigatePath,
    String Function()? currentPathProvider,
    InvitesRepositoryContract? invitesRepository,
    DateTime Function()? now,
  })  : _navigatePath = navigatePath,
        _currentPathProvider = currentPathProvider ?? (() => ''),
        _invitesRepository = invitesRepository,
        _now = now ?? DateTime.now;

  static const Duration _tapDedupeWindow = Duration(minutes: 2);

  final Future<void> Function(String path) _navigatePath;
  final String Function() _currentPathProvider;
  final InvitesRepositoryContract? _invitesRepository;
  final DateTime Function() _now;
  final InvitePushPayloadDecoder _payloadDecoder =
      const InvitePushPayloadDecoder();
  final Map<String, DateTime> _handledTapKeys = <String, DateTime>{};

  Future<void> handleIncomingMessage(RemoteMessage message) async {
    final payload = _normalizePayload(message.data);
    if (!_isInvitePush(payload)) {
      return;
    }

    _applyInvitePayload(payload);
    await _refreshInviteStateIfNeeded(payload);
  }

  String? prepareNotificationTapPath(RemoteMessage message) {
    final payload = _normalizePayload(message.data);
    if (!_isInvitePush(payload)) {
      return null;
    }

    final tapKey = _resolveTapKey(message: message, payload: payload);
    if (tapKey != null && !_claimTapKey(tapKey)) {
      return null;
    }

    _applyInvitePayload(payload);
    return _resolveNavigationPath(payload);
  }

  Future<void> refreshNotificationTapData(RemoteMessage message) async {
    final payload = _normalizePayload(message.data);
    if (!_isInvitePush(payload)) {
      return;
    }

    await _refreshInviteStateIfNeeded(payload);
  }

  Future<void> handleNotificationTap(RemoteMessage message) async {
    final path = prepareNotificationTapPath(message);
    if (path == null) {
      return;
    }

    unawaited(refreshNotificationTapData(message));
    await _navigateIfNeeded(path);
  }

  void _applyInvitePayload(Map<String, dynamic> payload) {
    final invitesRepository = _invitesRepository;
    if (invitesRepository == null) {
      return;
    }

    if (invitesRepository is PushInvitePayloadAware) {
      (invitesRepository as PushInvitePayloadAware)
          .applyInvitePushPayload(payload);
    }
  }

  Future<void> _refreshPendingInvitesIfNeeded(
    Map<String, dynamic> payload,
  ) async {
    final invitesRepository = _invitesRepository;
    if (invitesRepository == null) {
      return;
    }

    if (_payloadDecoder.decodeInviteDtos(payload).isNotEmpty) {
      return;
    }

    try {
      await invitesRepository.refreshPendingInvites();
    } catch (error) {
      debugPrint('[Push] Invite refresh failed after receipt: $error');
    }
  }

  Future<void> _refreshInviteStateIfNeeded(
    Map<String, dynamic> payload,
  ) async {
    final acceptedPayload = _payloadDecoder.decodeAcceptedSentInvite(payload);
    if (acceptedPayload != null) {
      await _refreshAcceptedSentInviteStatusIfNeeded(acceptedPayload);
      return;
    }

    await _refreshPendingInvitesIfNeeded(payload);
  }

  Future<void> _refreshAcceptedSentInviteStatusIfNeeded(
    InviteAcceptedPushPayload payload,
  ) async {
    final invitesRepository = _invitesRepository;
    if (invitesRepository == null) {
      return;
    }

    try {
      await invitesRepository.refreshSentInvitesForOccurrence(
        occurrenceId: invitesRepoString(
          payload.occurrenceId,
          defaultValue: '',
          isRequired: true,
        ),
        eventId: payload.eventId == null
            ? null
            : invitesRepoString(
                payload.eventId,
                defaultValue: '',
                isRequired: true,
              ),
        recipientAccountProfileIds: payload.accountProfileId == null
            ? const <InvitesRepositoryContractPrimString>[]
            : [
                invitesRepoString(
                  payload.accountProfileId,
                  defaultValue: '',
                  isRequired: true,
                ),
              ],
      );
      await invitesRepository.refreshSentInviteSummaryForOccurrence(
        occurrenceId: invitesRepoString(
          payload.occurrenceId,
          defaultValue: '',
          isRequired: true,
        ),
        eventId: payload.eventId == null
            ? null
            : invitesRepoString(
                payload.eventId,
                defaultValue: '',
                isRequired: true,
              ),
      );
    } catch (error) {
      debugPrint('[Push] Invite accepted status refresh failed: $error');
    }
  }

  String? _resolveNavigationPath(
    Map<String, dynamic> payload,
  ) {
    final fallbackPath = _resolveEventFallbackPath(payload) ?? '/';
    if (_payloadDecoder.decodeAcceptedSentInvite(payload) != null) {
      return fallbackPath;
    }

    final inviteId = _normalizeString(payload['invite_id']);
    if (inviteId != null && inviteId.isNotEmpty) {
      return _buildInvitePath(
        inviteId,
        fallbackPath: fallbackPath,
      );
    }

    if (fallbackPath != '/') {
      return fallbackPath;
    }

    return '/';
  }

  Map<String, dynamic> _normalizePayload(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(data);
  }

  bool _isInvitePush(Map<String, dynamic> payload) {
    final type = _pushType(payload);
    return type == 'invite_received' || type == 'invite_accepted';
  }

  String? _pushType(Map<String, dynamic> payload) {
    return _normalizeString(payload['push_type']) ??
        _normalizeString(payload['event']);
  }

  String? _resolveEventFallbackPath(
    Map<String, dynamic> payload,
  ) {
    final eventId = _normalizeString(payload['event_id']);
    if (eventId == null || eventId.isEmpty) {
      return null;
    }

    final occurrenceId = _normalizeString(payload['occurrence_id']);

    return Uri(
      path: '/agenda/evento/$eventId',
      queryParameters: occurrenceId == null || occurrenceId.isEmpty
          ? null
          : <String, String>{'occurrence': occurrenceId},
    ).toString();
  }

  String _buildInvitePath(
    String inviteId, {
    String? fallbackPath,
  }) {
    final normalizedFallback = fallbackPath?.trim();
    return Uri(
      path: '/convites',
      queryParameters: <String, String>{
        'invite': inviteId,
        if (normalizedFallback != null &&
            normalizedFallback.isNotEmpty &&
            normalizedFallback != '/')
          'fallback': normalizedFallback,
      },
    ).toString();
  }

  Future<void> _navigateIfNeeded(String path) async {
    final normalizedPath = path.trim();
    if (normalizedPath.isEmpty) {
      return;
    }
    if (_currentPathProvider().trim() == normalizedPath) {
      return;
    }
    await _navigatePath(normalizedPath);
  }

  String? _resolveTapKey({
    required RemoteMessage message,
    required Map<String, dynamic> payload,
  }) {
    final pushMessageId = _normalizeString(payload['push_message_id']);
    final messageInstanceId =
        _normalizeString(payload['message_instance_id']) ?? message.messageId;
    if (pushMessageId != null && pushMessageId.isNotEmpty) {
      return messageInstanceId == null || messageInstanceId.isEmpty
          ? pushMessageId
          : '$pushMessageId::$messageInstanceId';
    }
    return _normalizeString(payload['invite_id']) ?? messageInstanceId;
  }

  bool _claimTapKey(String key) {
    final now = _now();
    _handledTapKeys.removeWhere((_, handledAt) {
      return now.difference(handledAt) > _tapDedupeWindow;
    });
    if (_handledTapKeys.containsKey(key)) {
      return false;
    }
    _handledTapKeys[key] = now;
    return true;
  }

  String? _normalizeString(Object? value) {
    final normalized = value?.toString().trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}
