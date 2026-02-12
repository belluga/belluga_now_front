import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('setInitialLocation(null) clears previous pending selection', () {
    final service = TenantAdminLocationSelectionService();

    service.setInitialLocation(
      const TenantAdminLocation(latitude: -20.0, longitude: -40.0),
    );
    expect(service.currentLocation, isNotNull);

    service.setInitialLocation(null);

    expect(service.currentLocation, isNull);
  });
}
