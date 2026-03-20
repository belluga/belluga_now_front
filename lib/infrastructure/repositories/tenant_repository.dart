import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

class TenantRepository extends TenantRepositoryContract {
  static const String _tenantIdStorageKey = 'tenant_id';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  AppData get appData => GetIt.I.get<AppData>();

  @override
  Future<void> init() async {
    await super.init();
    await _persistTenantId();
  }

  @override
  Future<Tenant> fetchTenant() async {
    final mainDomainUri = appData.mainDomainValue.value;
    final mainDomainHost = mainDomainUri.host.trim();
    final domains = appData.domains
        .map((domain) => domain.value.toString())
        .where((domain) => domain.isNotEmpty)
        .toList(growable: false);
    final appDomains = appData.appDomains
        ?.map((domain) => domain.value)
        .where((domain) => domain.isNotEmpty)
        .toList(growable: false);

    final tenantName = appData.nameValue.value.trim().isNotEmpty
        ? appData.nameValue.value.trim()
        : (appData.tenantIdValue.value.isNotEmpty
            ? appData.tenantIdValue.value
            : mainDomainHost);

    return Tenant.fromPrimitives(
      name: tenantName,
      subdomain: _resolveSubdomain(mainDomainHost),
      mainLogoUrl: appData.mainLogoUrl.value.toString(),
      iconUrl: appData.iconUrl.value.toString(),
      mainColor: appData.mainColor.value,
      domains: domains,
      appDomains: appDomains,
    );
  }

  String _resolveSubdomain(String mainDomainHost) {
    final normalizedMainHost = mainDomainHost.trim();
    if (normalizedMainHost.isEmpty) {
      return appData.tenantIdValue.value;
    }

    final normalizedLandlordHost = landlordHost.trim();
    if (normalizedLandlordHost.isNotEmpty &&
        normalizedMainHost.endsWith('.$normalizedLandlordHost')) {
      final suffixLength = normalizedLandlordHost.length + 1;
      final candidate = normalizedMainHost.substring(
        0,
        normalizedMainHost.length - suffixLength,
      );
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }

    final segments = normalizedMainHost.split('.');
    if (segments.length > 2 && segments.first.isNotEmpty) {
      return segments.first;
    }

    if (appData.tenantIdValue.value.isNotEmpty) {
      return appData.tenantIdValue.value;
    }

    return normalizedMainHost;
  }

  Future<void> _persistTenantId() async {
    final tenantId = appData.tenantIdValue.value;
    if (tenantId.isEmpty) return;
    await _storage.write(key: _tenantIdStorageKey, value: tenantId);
  }
}
