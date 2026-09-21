String tenantAdminCapabilityDomainLabel(String domain) => switch (domain) {
  'visibility' => 'Visibilidade',
  'relationships' => 'Relacionamentos',
  'profile_content' => 'Perfil e conteúdo',
  'events' => 'Eventos',
  'location' => 'Localização',
  _ => domain,
};

String tenantAdminCapabilityLabel(String key) {
  final normalized = key.replaceAll('_', ' ').trim();
  if (normalized.isEmpty) {
    return key;
  }
  return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
}
