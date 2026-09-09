abstract base class GalleryItem {
  const GalleryItem({required this.itemId, this.title, this.description});

  final String itemId;
  final String? title;
  final String? description;
}
