import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/services/tenant_admin_location_selection_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminLocationPickerController {
  TenantAdminLocationPickerController({
    TenantAdminLocationSelectionService? locationSelectionService,
  }) : _locationSelectionService = locationSelectionService ??
            (GetIt.I.isRegistered<TenantAdminLocationSelectionService>()
                ? GetIt.I.get<TenantAdminLocationSelectionService>()
                : TenantAdminLocationSelectionService());

  final TenantAdminLocationSelectionService _locationSelectionService;
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
