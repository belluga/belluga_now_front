typedef TenantAdminCreateTypeWithoutVisual<TDefinition, TCapabilities>
    = Future<TDefinition> Function({
  required String type,
  required String label,
  required List<String> allowedTaxonomies,
  required TCapabilities capabilities,
});

typedef TenantAdminCreateTypeWithVisual<TDefinition, TCapabilities, TVisual>
    = Future<TDefinition> Function({
  required String type,
  required String label,
  required List<String> allowedTaxonomies,
  required TCapabilities capabilities,
  TVisual? visual,
  Object? typeAssetUpload,
});

typedef TenantAdminUpdateTypeWithoutVisual<TDefinition, TCapabilities>
    = Future<TDefinition> Function({
  required String type,
  String? newType,
  String? label,
  List<String>? allowedTaxonomies,
  TCapabilities? capabilities,
});

typedef TenantAdminUpdateTypeWithVisual<TDefinition, TCapabilities, TVisual>
    = Future<TDefinition> Function({
  required String type,
  String? newType,
  String? label,
  List<String>? allowedTaxonomies,
  TCapabilities? capabilities,
  TVisual? visual,
  Object? typeAssetUpload,
  bool? removeTypeAsset,
});

Future<TDefinition> tenantAdminCreateTypeWithOptionalVisual<TDefinition,
    TCapabilities, TVisual>({
  required bool includeVisual,
  required String type,
  required String label,
  required List<String> allowedTaxonomies,
  required TCapabilities capabilities,
  required TVisual? visual,
  required Object? typeAssetUpload,
  required TenantAdminCreateTypeWithoutVisual<TDefinition, TCapabilities>
      createWithoutVisual,
  required TenantAdminCreateTypeWithVisual<TDefinition, TCapabilities, TVisual>
      createWithVisual,
}) {
  if (includeVisual) {
    return createWithVisual(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
      visual: visual,
      typeAssetUpload: typeAssetUpload,
    );
  }

  return createWithoutVisual(
    type: type,
    label: label,
    allowedTaxonomies: allowedTaxonomies,
    capabilities: capabilities,
  );
}

Future<TDefinition> tenantAdminUpdateTypeWithOptionalVisual<TDefinition,
    TCapabilities, TVisual>({
  required bool includeVisual,
  required String type,
  required String? newType,
  required String? label,
  required List<String>? allowedTaxonomies,
  required TCapabilities? capabilities,
  required TVisual? visual,
  required Object? typeAssetUpload,
  required bool? removeTypeAsset,
  required TenantAdminUpdateTypeWithoutVisual<TDefinition, TCapabilities>
      updateWithoutVisual,
  required TenantAdminUpdateTypeWithVisual<TDefinition, TCapabilities, TVisual>
      updateWithVisual,
}) {
  if (includeVisual) {
    return updateWithVisual(
      type: type,
      newType: newType,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
      visual: visual,
      typeAssetUpload: typeAssetUpload,
      removeTypeAsset: removeTypeAsset,
    );
  }

  return updateWithoutVisual(
    type: type,
    newType: newType,
    label: label,
    allowedTaxonomies: allowedTaxonomies,
    capabilities: capabilities,
  );
}
