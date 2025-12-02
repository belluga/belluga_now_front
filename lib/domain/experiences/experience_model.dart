class ExperienceModel {
  ExperienceModel({
    required this.id,
    required this.title,
    required this.category,
    required this.providerName,
    required this.providerId,
    this.description = '',
    this.imageUrl,
    this.highlightItems = const [],
    this.tags = const [],
    this.duration,
    this.priceLabel,
    this.meetingPoint,
  });

  final String id;
  final String title;
  final String category;
  final String providerName;
  final String providerId;
  final String description;
  final String? imageUrl;
  final List<String> highlightItems;
  final List<String> tags;
  final String? duration;
  final String? priceLabel;
  final String? meetingPoint;
}
