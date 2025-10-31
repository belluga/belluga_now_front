import 'package:intl/intl.dart';

class EventCardData {
  const EventCardData({
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
}
