import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/repositories/inviteables_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_backend_requests.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/invites_backend/laravel_invites_backend.dart';
import 'package:belluga_now/infrastructure/observability/invite_flow_debug_logger.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';

class InviteablesRepository extends InviteablesRepositoryContract {
  static const int routeCriticalPageSize = 50;

  InviteablesRepository({InvitesBackendContract? backend})
    : _backend = backend ?? LaravelInvitesBackend();

  final InvitesBackendContract _backend;
  final InvitesResponseDecoder _responseDecoder =
      const InvitesResponseDecoder();
  Future<List<InviteableRecipient>>? _activeRefresh;

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() {
    final activeRefresh = _activeRefresh;
    if (activeRefresh != null) {
      InviteFlowDebugLogger.logPagedFetch(
        'contacts.inviteables.repository.reuse_active_refresh',
        page: 1,
        pageSize: routeCriticalPageSize,
      );
      return activeRefresh;
    }

    late final Future<List<InviteableRecipient>> refresh;
    refresh = _fetchAndStoreInviteableRecipients().whenComplete(() {
      if (identical(_activeRefresh, refresh)) {
        _activeRefresh = null;
      }
    });
    _activeRefresh = refresh;
    return refresh;
  }

  Future<List<InviteableRecipient>> _fetchAndStoreInviteableRecipients() async {
    final traceId = InviteFlowDebugLogger.nextTraceId(
      'contacts.inviteables.repository',
    );
    InviteFlowDebugLogger.logPagedFetch(
      'contacts.inviteables.repository.start',
      traceId: traceId,
      page: 1,
      pageSize: routeCriticalPageSize,
    );
    final response = await _backend.fetchInviteableContacts(
      const InviteableContactsRequest(page: 1, pageSize: routeCriticalPageSize),
    );
    final recipients = _responseDecoder.decodeInviteableRecipients(
      _responseDecoder.itemsPayload(response),
    );
    InviteFlowDebugLogger.logCount(
      'contacts.inviteables.repository.decoded',
      traceId: traceId,
      field: 'decoded_recipient_count',
      count: recipients.length,
    );
    inviteableRecipientsStreamValue.addValue(recipients);
    return recipients;
  }
}
