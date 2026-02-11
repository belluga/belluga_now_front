import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminLocationSelectionContract {
  StreamValue<TenantAdminLocation?> get locationStreamValue;
  StreamValue<TenantAdminLocation?> get confirmedLocationStreamValue;

  TenantAdminLocation? get currentLocation;
  TenantAdminLocation? get confirmedLocation;

  void setInitialLocation(TenantAdminLocation? location);
  void setLocation(TenantAdminLocation location);
  void confirmSelection();
  void clearConfirmedLocation();
}
