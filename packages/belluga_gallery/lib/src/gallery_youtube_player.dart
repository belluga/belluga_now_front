import 'gallery_item.dart';

final class GalleryYoutubePlayer extends GalleryItem {
  const GalleryYoutubePlayer({
    required super.itemId,
    required this.youtubeVideoId,
    super.title,
    super.description,
    this.playerAspectRatio = 16 / 9,
  }) : assert(playerAspectRatio > 0);

  final String youtubeVideoId;
  final double playerAspectRatio;

  String get thumbnailUrl =>
      'https://i.ytimg.com/vi/$youtubeVideoId/hqdefault.jpg';
}
