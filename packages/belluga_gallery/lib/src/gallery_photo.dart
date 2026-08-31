import 'gallery_item.dart';

final class GalleryPhoto extends GalleryItem {
  const GalleryPhoto({
    required super.itemId,
    required this.imageUrl,
    super.description,
    this.thumbUrl = '',
    this.cardUrl = '',
    this.modalUrl = '',
  });

  final String imageUrl;
  final String thumbUrl;
  final String cardUrl;
  final String modalUrl;

  String get previewUrl {
    for (final candidate in <String>[thumbUrl, cardUrl, imageUrl, modalUrl]) {
      if (candidate.trim().isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }

  String get viewerUrl {
    for (final candidate in <String>[modalUrl, imageUrl, cardUrl, thumbUrl]) {
      if (candidate.trim().isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }
}
