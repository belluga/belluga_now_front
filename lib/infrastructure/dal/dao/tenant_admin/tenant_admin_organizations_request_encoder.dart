class TenantAdminOrganizationsRequestEncoder {
  const TenantAdminOrganizationsRequestEncoder();

  Map<String, dynamic> encodeOrganizationUpdate({
    String? name,
    String? slug,
    String? description,
  }) {
    final payload = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }
    if (slug != null && slug.trim().isNotEmpty) {
      payload['slug'] = slug.trim();
    }
    if (description != null) {
      payload['description'] = description.trim();
    }
    return payload;
  }
}
