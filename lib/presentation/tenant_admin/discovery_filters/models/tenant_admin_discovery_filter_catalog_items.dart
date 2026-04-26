import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_catalog_item.dart';

class TenantAdminDiscoveryFilterCatalogItems
    extends Iterable<TenantAdminDiscoveryFilterCatalogItem> {
  TenantAdminDiscoveryFilterCatalogItems([
    Iterable<TenantAdminDiscoveryFilterCatalogItem>? items,
  ]) : _items = List<TenantAdminDiscoveryFilterCatalogItem>.from(
          items ?? const <TenantAdminDiscoveryFilterCatalogItem>[],
        );

  const TenantAdminDiscoveryFilterCatalogItems.empty()
      : _items = const <TenantAdminDiscoveryFilterCatalogItem>[];

  final List<TenantAdminDiscoveryFilterCatalogItem> _items;

  @override
  Iterator<TenantAdminDiscoveryFilterCatalogItem> get iterator =>
      _items.iterator;

  @override
  int get length => _items.length;

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  TenantAdminDiscoveryFilterCatalogItem elementAt(int index) =>
      _items.elementAt(index);

  void add(TenantAdminDiscoveryFilterCatalogItem item) {
    _items.add(item);
  }

  @override
  List<TenantAdminDiscoveryFilterCatalogItem> toList({bool growable = true}) =>
      List<TenantAdminDiscoveryFilterCatalogItem>.from(
        _items,
        growable: growable,
      );
}
