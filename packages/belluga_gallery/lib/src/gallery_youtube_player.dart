import 'gallery_item.dart';

final class GalleryYoutubePlayer extends GalleryItem {
  const GalleryYoutubePlayer({
    required super.itemId,
    required this.youtubeVideoId,
    super.description,
  });

  final String youtubeVideoId;

  String get thumbnailUrl =>
      'https://i.ytimg.com/vi/$youtubeVideoId/hqdefault.jpg';
}
