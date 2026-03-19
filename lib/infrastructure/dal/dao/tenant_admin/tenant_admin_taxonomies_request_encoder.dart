class TenantAdminTaxonomiesRequestEncoder {
  const TenantAdminTaxonomiesRequestEncoder();

  Map<String, dynamic> encodeTaxonomyUpdate({
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) {
    final payload = <String, dynamic>{};
    if (slug != null && slug.trim().isNotEmpty) {
      payload['slug'] = slug.trim();
    }
    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }
    if (appliesTo != null) {
      payload['applies_to'] = appliesTo;
    }
    if (icon != null) {
      payload['icon'] = icon.trim();
    }
    if (color != null) {
      payload['color'] = color.trim();
    }
    return payload;
  }

  Map<String, dynamic> encodeTermUpdate({
    String? slug,
    String? name,
  }) {
    final payload = <String, dynamic>{};
    if (slug != null && slug.trim().isNotEmpty) {
      payload['slug'] = slug.trim();
    }
    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }
    return payload;
  }
}
