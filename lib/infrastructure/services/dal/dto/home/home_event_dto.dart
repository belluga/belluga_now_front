import 'package:belluga_now/domain/home/home_event.dart';

class HomeEventDTO {
  const HomeEventDTO({
    required this.title,
    required this.imageUrl,
    required this.startDateTime,
    required this.location,
    required this.artist,
  });

  final String title;
  final String imageUrl;
  final DateTime startDateTime;
  final String location;
  final String artist;

  HomeEvent toDomain() {
    return HomeEvent(
      title: title,
      imageUrl: imageUrl,
      startDateTime: startDateTime,
      location: location,
      artist: artist,
    );
  }
}
