class UpcomingEventData {
  const UpcomingEventData({
    required this.title,
    required this.category,
    required this.price,
    required this.distance,
    required this.rating,
    required this.description,
  });

  final String title;
  final String category;
  final String price;
  final String distance;
  final int rating;
  final String description;
}