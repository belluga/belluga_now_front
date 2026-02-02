import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminLocationPickerController {
  final MapController mapController = MapController();
  final StreamValue<TenantAdminLocation?> _locationStreamValue =
      StreamValue<TenantAdminLocation?>(defaultValue: null);

  StreamValue<TenantAdminLocation?> get locationStreamValue =>
      _locationStreamValue;

  TenantAdminLocation? get currentLocation => _locationStreamValue.value;

  void setInitialLocation(TenantAdminLocation? location) {
    if (location == null) {
      return;
    }
    _locationStreamValue.addValue(location);
  }

  void setLocation(TenantAdminLocation location) {
    _locationStreamValue.addValue(location);
  }

  void dispose() {
    mapController.dispose();
    _locationStreamValue.dispose();
  }
}
