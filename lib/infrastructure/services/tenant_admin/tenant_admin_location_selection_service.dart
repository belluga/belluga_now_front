import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminLocationSelectionService
    implements TenantAdminLocationSelectionContract, Disposable {
  final StreamValue<TenantAdminLocation?> _locationStreamValue =
      StreamValue<TenantAdminLocation?>(defaultValue: null);
  final StreamValue<TenantAdminLocation?> _confirmedLocationStreamValue =
      StreamValue<TenantAdminLocation?>(defaultValue: null);

  @override
  StreamValue<TenantAdminLocation?> get locationStreamValue =>
      _locationStreamValue;

  @override
  StreamValue<TenantAdminLocation?> get confirmedLocationStreamValue =>
      _confirmedLocationStreamValue;

  @override
  TenantAdminLocation? get currentLocation => _locationStreamValue.value;

  @override
  TenantAdminLocation? get confirmedLocation =>
      _confirmedLocationStreamValue.value;

  @override
  void setInitialLocation(TenantAdminLocation? location) {
    if (location == null) return;
    _locationStreamValue.addValue(location);
  }

  @override
  void setLocation(TenantAdminLocation location) {
    _locationStreamValue.addValue(location);
  }

  @override
  void confirmSelection() {
    final location = _locationStreamValue.value;
    if (location == null) return;
    _confirmedLocationStreamValue.addValue(location);
  }

  @override
  void clearConfirmedLocation() {
    _confirmedLocationStreamValue.addValue(null);
  }

  @override
  void onDispose() {
    _locationStreamValue.dispose();
    _confirmedLocationStreamValue.dispose();
  }
}
