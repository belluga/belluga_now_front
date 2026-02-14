import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';

abstract class TenantRepositoryContract {
  AppData get appData;

  Future<Tenant> fetchTenant();

  Tenant? tenant;

  String get landlordDomain => BellugaConstants.landlordDomain;

  String get landlordHost {
    final raw = landlordDomain.trim();
    if (raw.isEmpty) {
      return '';
    }

    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.host.trim().isNotEmpty) {
      return parsed.host.trim();
    }

    return raw;
  }

  Future<void> init() async {
    final loadedTenant = await _getTenant();
    _setTenant(loadedTenant);
  }

  bool get isLandlordRequest =>
      landlordHost.isNotEmpty && landlordHost == appData.hostname;

  bool get isProperTenantRegistered {
    final currentTenant = tenant;
    if (currentTenant == null) {
      return false;
    }

    return currentTenant.hasDomain(appData.hostname);
  }

  Future<Tenant> _getTenant() async {
    return fetchTenant();
  }

  void _setTenant(Tenant newTenant) => tenant = newTenant;

  void clearTenant() {
    tenant = null;
  }
}
