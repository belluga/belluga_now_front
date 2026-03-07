bool isDtoUri(String uri) {
  final normalized = uri.toLowerCase();

  return normalized.contains('/dto/') ||
      normalized.contains('/dtos/') ||
      normalized.contains('/dal/dto/') ||
      normalized.contains('_dto.dart');
}
