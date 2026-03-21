part of 'mock_schedule_backend.dart';

class MockEventSeed {
  const MockEventSeed({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.thumbUrl,
    required this.offsetDays,
    required this.startHour,
    this.durationMinutes = 90,
    required this.artists,
    this.isConfirmed = false,
    this.totalConfirmed = 0,
    this.receivedInvites = const [],
    this.sentInvites = const [],
    this.friendsGoing = const [],
    this.tags = const [],
  });

  final String id;
  final EventTypeDTO type;
  final String title;
  final String content;
  final String location;
  final double latitude;
  final double longitude;
  final String thumbUrl;
  final int offsetDays;
  final int startHour;
  final int durationMinutes;
  final List<MockArtistSeed> artists;
  final bool isConfirmed;
  final int totalConfirmed;
  final List<Map<String, dynamic>> receivedInvites;
  final List<Map<String, dynamic>> sentInvites;
  final List<Map<String, dynamic>> friendsGoing;
  final List<String> tags;

  MockEventSeed copyWith({
    String? id,
    int? offsetDays,
    int? startHour,
    int? durationMinutes,
    List<String>? tags,
    List<Map<String, dynamic>>? receivedInvites,
  }) {
    return MockEventSeed(
      id: id ?? this.id,
      type: type,
      title: title,
      content: content,
      location: location,
      latitude: latitude,
      longitude: longitude,
      thumbUrl: thumbUrl,
      offsetDays: offsetDays ?? this.offsetDays,
      startHour: startHour ?? this.startHour,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      artists: artists,
      isConfirmed: isConfirmed,
      totalConfirmed: totalConfirmed,
      receivedInvites: receivedInvites ?? this.receivedInvites,
      sentInvites: sentInvites,
      friendsGoing: friendsGoing,
      tags: tags ?? this.tags,
    );
  }

  EventDTO _toDto(DateTime today, _EventVenue venue) {
    final start = today
        .add(Duration(days: offsetDays))
        .add(Duration(hours: startHour))
        .toIso8601String();
    final end = today
        .add(Duration(days: offsetDays))
        .add(Duration(hours: startHour, minutes: durationMinutes))
        .toIso8601String();

    final venueSlug = MockScheduleBackend._slugify(venue.name);
    return EventDTO(
      id: MockScheduleBackend.generateMongoId(id),
      slug: id,
      type: type,
      title: title,
      content: content,
      dateTimeStart: start,
      dateTimeEnd: end,
      location: location.isNotEmpty ? location : venue.name,
      latitude: latitude,
      longitude: longitude,
      venue: {
        'id': MockScheduleBackend.generateMongoId(venueSlug),
        'display_name': venue.name,
        'tagline': venue.address,
        'slug': venueSlug,
        'logo_url': thumbUrl,
        'hero_image_url': thumbUrl,
      },
      thumb: ThumbDTO(
        type: 'image',
        data: {'url': thumbUrl},
      ),
      artists: artists.map((artist) => artist.toDto()).toList(),
      isConfirmed: isConfirmed,
      totalConfirmed: totalConfirmed,
      friendsGoing: friendsGoing,
      receivedInvites: receivedInvites,
      sentInvites: sentInvites,
      tags: tags,
    );
  }
}
