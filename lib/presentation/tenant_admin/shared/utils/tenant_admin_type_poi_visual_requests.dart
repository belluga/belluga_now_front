typedef TenantAdminCreateTypeWithoutPoiVisual<TDefinition, TCapabilities>
    = Future<TDefinition> Function({
  required String type,
  required String label,
  required List<String> allowedTaxonomies,
  required TCapabilities capabilities,
});

typedef TenantAdminCreateTypeWithPoiVisual<TDefinition, TCapabilities,
        TPoiVisual>
    = Future<TDefinition> Function({
  required String type,
  required String label,
  required List<String> allowedTaxonomies,
  required TCapabilities capabilities,
  TPoiVisual? poiVisual,
});

typedef TenantAdminUpdateTypeWithoutPoiVisual<TDefinition, TCapabilities>
    = Future<TDefinition> Function({
  required String type,
  String? newType,
  String? label,
  List<String>? allowedTaxonomies,
  TCapabilities? capabilities,
});

typedef TenantAdminUpdateTypeWithPoiVisual<TDefinition, TCapabilities,
        TPoiVisual>
    = Future<TDefinition> Function({
  required String type,
  String? newType,
  String? label,
  List<String>? allowedTaxonomies,
  TCapabilities? capabilities,
  TPoiVisual? poiVisual,
});

Future<TDefinition> tenantAdminCreateTypeWithOptionalPoiVisual<TDefinition,
    TCapabilities, TPoiVisual>({
  required bool includePoiVisual,
  required String type,
  required String label,
  required List<String> allowedTaxonomies,
  required TCapabilities capabilities,
  required TPoiVisual? poiVisual,
  required TenantAdminCreateTypeWithoutPoiVisual<TDefinition, TCapabilities>
      createWithoutPoiVisual,
  required TenantAdminCreateTypeWithPoiVisual<TDefinition, TCapabilities,
          TPoiVisual>
      createWithPoiVisual,
}) {
  if (includePoiVisual) {
    return createWithPoiVisual(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
      poiVisual: poiVisual,
    );
  }

  return createWithoutPoiVisual(
    type: type,
    label: label,
    allowedTaxonomies: allowedTaxonomies,
    capabilities: capabilities,
  );
}

Future<TDefinition> tenantAdminUpdateTypeWithOptionalPoiVisual<TDefinition,
    TCapabilities, TPoiVisual>({
  required bool includePoiVisual,
  required String type,
  required String? newType,
  required String? label,
  required List<String>? allowedTaxonomies,
  required TCapabilities? capabilities,
  required TPoiVisual? poiVisual,
  required TenantAdminUpdateTypeWithoutPoiVisual<TDefinition, TCapabilities>
      updateWithoutPoiVisual,
  required TenantAdminUpdateTypeWithPoiVisual<TDefinition, TCapabilities,
          TPoiVisual>
      updateWithPoiVisual,
}) {
  if (includePoiVisual) {
    return updateWithPoiVisual(
      type: type,
      newType: newType,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
      poiVisual: poiVisual,
    );
  }

  return updateWithoutPoiVisual(
    type: type,
    newType: newType,
    label: label,
    allowedTaxonomies: allowedTaxonomies,
    capabilities: capabilities,
  );
}
