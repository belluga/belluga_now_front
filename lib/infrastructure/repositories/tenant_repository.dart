import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

class TenantRepository extends TenantRepositoryContract {
  static const String _tenantIdStorageKey = 'tenant_id';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  AppData get appData => GetIt.I.get<AppData>();

  BackendContract get _backend => GetIt.I.get<BackendContract>();

  @override
  Future<void> init() async {
    await super.init();
    await _persistTenantId();
  }

  @override
  Future<Tenant> fetchTenant() async {
    final loadedTenant = await _backend.tenant.getTenant().catchError((error) {
      throw Exception('Failed to retrieve tenant: $error');
    });
    return loadedTenant;
  }

  Future<void> _persistTenantId() async {
    final tenantId = appData.tenantIdValue.value;
    if (tenantId.isEmpty) return;
    await _storage.write(key: _tenantIdStorageKey, value: tenantId);
  }
}
