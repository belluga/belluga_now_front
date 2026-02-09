import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:get_it/get_it.dart';

abstract class TenantRepositoryContract {
  AppData get appData;
  BackendContract get _backend => GetIt.I.get<BackendContract>();

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
    final loadedTenant = await _backend.tenant.getTenant().catchError((error) {
      throw Exception('Failed to retrieve tenant: $error');
    });
    return loadedTenant;
  }

  void _setTenant(Tenant newTenant) => tenant = newTenant;

  void clearTenant() {
    tenant = null;
  }
}
