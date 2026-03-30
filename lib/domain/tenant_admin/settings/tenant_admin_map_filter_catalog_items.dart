import 'dart:collection';

import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_catalog_item.dart';

class TenantAdminMapFilterCatalogItems
    extends IterableBase<TenantAdminMapFilterCatalogItem> {
  const TenantAdminMapFilterCatalogItems.empty()
      : _items = const <TenantAdminMapFilterCatalogItem>[];

  TenantAdminMapFilterCatalogItems()
      : _items = <TenantAdminMapFilterCatalogItem>[];

  final List<TenantAdminMapFilterCatalogItem> _items;

  void add(TenantAdminMapFilterCatalogItem item) {
    _items.add(item);
  }

  TenantAdminMapFilterCatalogItem get first => _items.first;

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;

  @override
  Iterator<TenantAdminMapFilterCatalogItem> get iterator => _items.iterator;
}
