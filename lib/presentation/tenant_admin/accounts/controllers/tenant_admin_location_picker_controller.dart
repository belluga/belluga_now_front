import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminLocationPickerController {
  TenantAdminLocationPickerController({
    TenantAdminLocationSelectionContract? locationSelectionService,
  }) : _locationSelectionService = locationSelectionService ??
            GetIt.I.get<TenantAdminLocationSelectionContract>();

  final TenantAdminLocationSelectionContract _locationSelectionService;
  final MapController mapController = MapController();

  StreamValue<TenantAdminLocation?> get locationStreamValue =>
      _locationSelectionService.locationStreamValue;
  StreamValue<TenantAdminLocation?> get confirmedLocationStreamValue =>
      _locationSelectionService.confirmedLocationStreamValue;

  TenantAdminLocation? get currentLocation =>
      _locationSelectionService.currentLocation;
  TenantAdminLocation? get confirmedLocation =>
      _locationSelectionService.confirmedLocation;

  void setInitialLocation(TenantAdminLocation? location) {
    _locationSelectionService.setInitialLocation(location);
  }

  void setLocation(TenantAdminLocation location) {
    _locationSelectionService.setLocation(location);
  }

  void confirmSelection() {
    _locationSelectionService.confirmSelection();
  }

  void clearConfirmedLocation() {
    _locationSelectionService.clearConfirmedLocation();
  }

  void dispose() {
    mapController.dispose();
  }
}
