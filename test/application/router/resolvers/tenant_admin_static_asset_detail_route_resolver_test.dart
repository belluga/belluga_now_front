import 'package:belluga_now/application/router/resolvers/tenant_admin_static_asset_detail_route_resolver.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_static_assets_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStaticAssetsRepository extends Fake
    implements TenantAdminStaticAssetsRepositoryContract {
  _FakeStaticAssetsRepository({
    this.expectedAsset,
  });

  final TenantAdminStaticAsset? expectedAsset;
  String? lastRequestedAssetId;

  @override
  Future<TenantAdminStaticAsset> fetchStaticAsset(String assetId) async {
    lastRequestedAssetId = assetId;
    if (expectedAsset == null) {
      throw StateError('No expected asset configured');
    }
    return expectedAsset!;
  }
}

void main() {
  group('TenantAdminStaticAssetDetailRouteResolver', () {
    test('loads static asset from route assetId', () async {
      final expected = TenantAdminStaticAsset(
        id: 'asset-1',
        profileType: 'poi',
        displayName: 'Asset',
        slug: 'asset',
        isActive: true,
      );
      final repository = _FakeStaticAssetsRepository(expectedAsset: expected);
      final resolver = TenantAdminStaticAssetDetailRouteResolver(
        staticAssetsRepository: repository,
      );

      final resolved = await resolver.resolve({'assetId': 'asset-1'});

      expect(resolved, same(expected));
      expect(repository.lastRequestedAssetId, 'asset-1');
    });

    test('throws when assetId is missing', () async {
      final repository = _FakeStaticAssetsRepository();
      final resolver = TenantAdminStaticAssetDetailRouteResolver(
        staticAssetsRepository: repository,
      );

      await expectLater(
        () => resolver.resolve(<String, dynamic>{}),
        throwsA(isA<ArgumentError>()),
      );
      expect(repository.lastRequestedAssetId, isNull);
    });
  });
}
