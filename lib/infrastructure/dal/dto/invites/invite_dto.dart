class InviteDto {
  final String id;
  final String eventId;
  final String eventName;
  final String eventDate;
  final String eventImageUrl;
  final String location;
  final String hostName;
  final String message;
  final List<String> tags;
  final String? inviterName;
  final String? inviterAvatarUrl;
  final List<String> additionalInviters;
  final String? inviterPrincipalKind;
  final String? inviterPrincipalId;

  InviteDto({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.eventImageUrl,
    required this.location,
    required this.hostName,
    required this.message,
    required this.tags,
    this.inviterName,
    this.inviterAvatarUrl,
    required this.additionalInviters,
    this.inviterPrincipalKind,
    this.inviterPrincipalId,
  });

  factory InviteDto.fromJson(Map<String, dynamic> json) {
    final inviterPrincipal = json['inviter_principal'];
    final inviterPrincipalMap =
        inviterPrincipal is Map<String, dynamic> ? inviterPrincipal : null;
    return InviteDto(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      eventName: json['event_name'] as String,
      eventDate: json['event_date'] as String,
      eventImageUrl: json['event_image_url'] as String,
      location: json['location'] as String,
      hostName: json['host_name'] as String,
      message: json['message'] as String,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      inviterName: json['inviter_name'] as String?,
      inviterAvatarUrl: json['inviter_avatar_url'] as String?,
      additionalInviters: (json['additional_inviters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      inviterPrincipalKind: inviterPrincipalMap?['kind'] as String?,
      inviterPrincipalId: inviterPrincipalMap?['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final inviterPrincipal = inviterPrincipalId == null
        ? null
        : {
            'kind': inviterPrincipalKind,
            'id': inviterPrincipalId,
          };
    return {
      'id': id,
      'event_id': eventId,
      'event_name': eventName,
      'event_date': eventDate,
      'event_image_url': eventImageUrl,
      'location': location,
      'host_name': hostName,
      'message': message,
      'tags': tags,
      'inviter_name': inviterName,
      'inviter_avatar_url': inviterAvatarUrl,
      'additional_inviters': additionalInviters,
      if (inviterPrincipal != null) 'inviter_principal': inviterPrincipal,
    };
  }
}
