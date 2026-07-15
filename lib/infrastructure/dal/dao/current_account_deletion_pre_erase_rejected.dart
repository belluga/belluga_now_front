import 'package:belluga_now/infrastructure/dal/dao/account_deletion_backend_result_base.dart';

class CurrentAccountDeletionPreEraseRejected
    extends CurrentAccountDeletionBackendResult {
  const CurrentAccountDeletionPreEraseRejected(this.statusCode);

  final int statusCode;
}
