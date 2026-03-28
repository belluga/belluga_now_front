import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
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
  DomainBooleanValue _disposedValue = DomainBooleanValue()
    ..parse(false.toString());

  void dispose() {
    if (_disposedValue.value) {
      return;
    }
    _disposedValue = DomainBooleanValue()..parse(true.toString());
    _onDispose();
    streamValue.dispose();
  }
}
