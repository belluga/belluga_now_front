import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/backend_contract.dart';

abstract class TenantRepositoryContract {
  BackendContract get backend;
  AppData get appData;

  Tenant? tenant;

  String get landlordDomain => BellugaConstants.landlordDomain;

  Future<void> init() async {
    final _tenant = await _getTenant();
    _setTenant(_tenant);
  }

  bool get isLandlordRequest => landlordDomain == appData.hostname;

  bool get isProperTenantRegistered {

    final Tenant? _tenant = tenant;

    if (_tenant == null) {
      return false;
    }
    return _tenant.hasDomain(appData.hostname);
  }

  Future<Tenant> _getTenant() async {
    final _tenant = await backend.tenant.getTenant().catchError((error) {
      throw Exception("Failed to retrieve tenant: $error");
    });
    return _tenant;
  }

  void _setTenant(Tenant newTenant) => tenant = newTenant;

  void clearTenant() {
    tenant = null;
  }
}
