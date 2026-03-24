import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:stream_value/core/stream_value.dart';

typedef TenantAdminLoadedAccountWatchPrimString = String;
typedef TenantAdminLoadedAccountWatchPrimInt = int;
typedef TenantAdminLoadedAccountWatchPrimBool = bool;
typedef TenantAdminLoadedAccountWatchPrimDouble = double;
typedef TenantAdminLoadedAccountWatchPrimDateTime = DateTime;
typedef TenantAdminLoadedAccountWatchPrimDynamic = dynamic;

class TenantAdminLoadedAccountWatch {
  TenantAdminLoadedAccountWatch({
    required this.streamValue,
    required void Function() onDispose,
  }) : _onDispose = onDispose;

  final StreamValue<TenantAdminAccount?> streamValue;
  final void Function() _onDispose;
  TenantAdminLoadedAccountWatchPrimBool _disposed = false;

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _onDispose();
    streamValue.dispose();
  }
}
