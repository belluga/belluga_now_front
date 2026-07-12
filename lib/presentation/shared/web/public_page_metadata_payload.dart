class PublicPageMetadataPayload {
  const PublicPageMetadataPayload({
    required this.title,
    required this.description,
    required this.url,
    this.imageUrl,
  });

  final String title;
  final String description;
  final String url;
  final String? imageUrl;
}
