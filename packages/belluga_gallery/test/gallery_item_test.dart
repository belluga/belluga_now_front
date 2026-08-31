import 'package:belluga_gallery/belluga_gallery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('photo chooses the smallest available preview variant', () {
    const photo = GalleryPhoto(
      itemId: 'photo-1',
      imageUrl: 'image',
      thumbUrl: 'thumb',
      cardUrl: 'card',
      modalUrl: 'modal',
    );

    expect(photo.previewUrl, 'thumb');
  });

  test('youtube item exposes the official static thumbnail URL', () {
    const video = GalleryYoutubePlayer(
      itemId: 'video-1',
      youtubeVideoId: 'dQw4w9WgXcQ',
    );

    expect(
      video.thumbnailUrl,
      'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
    );
  });
}
