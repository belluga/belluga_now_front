class InviteModel {
  const InviteModel({
    required this.id,
    required this.eventName,
    required this.eventDateTime,
    required this.eventImageUrl,
    required this.location,
    required this.hostName,
    required this.message,
    required this.tags,
  });

  final String id;
  final String eventName;
  final DateTime eventDateTime;
  final String eventImageUrl;
  final String location;
  final String hostName;
  final String message;
  final List<String> tags;
}
