import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/repositories/inviteables_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_backend_requests.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_response_decoder.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/invites_backend/laravel_invites_backend.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';

class InviteablesRepository extends InviteablesRepositoryContract {
  static const int routeCriticalPageSize = 50;

  InviteablesRepository({
    InvitesBackendContract? backend,
  }) : _backend = backend ?? LaravelInvitesBackend();

  final InvitesBackendContract _backend;
  final InvitesResponseDecoder _responseDecoder =
      const InvitesResponseDecoder();
  Future<List<InviteableRecipient>>? _activeRefresh;

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() {
    final activeRefresh = _activeRefresh;
    if (activeRefresh != null) {
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
    final response = await _backend.fetchInviteableContacts(
      const InviteableContactsRequest(
        page: 1,
        pageSize: routeCriticalPageSize,
      ),
    );
    final recipients = _responseDecoder.decodeInviteableRecipients(
      _responseDecoder.itemsPayload(response),
    );
    inviteableRecipientsStreamValue.addValue(recipients);
    return recipients;
  }
}
