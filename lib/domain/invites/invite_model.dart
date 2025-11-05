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
    this.inviterName,
    this.inviterAvatarUrl,
    this.additionalInviters = const [],
    this.inviters = const [],
  });

  final String id;
  final String eventName;
  final DateTime eventDateTime;
  final String eventImageUrl;
  final String location;
  final String hostName;
  final String message;
  final List<String> tags;
  final String? inviterName;
  final String? inviterAvatarUrl;
  final List<String> additionalInviters;
  final List<InviteInviter> inviters;
}

class InviteInviter {
  const InviteInviter({
    required this.type,
    required this.name,
    this.avatarUrl,
    this.partner,
  });

  final InviteInviterType type;
  final String name;
  final String? avatarUrl;
  final InvitePartnerSummary? partner;
}

enum InviteInviterType {
  user,
  partner,
}

class InvitePartnerSummary {
  const InvitePartnerSummary({
    required this.id,
    required this.name,
    required this.type,
    this.tagline,
    this.heroImageUrl,
    this.logoImageUrl,
  });

  final String id;
  final String name;
  final InvitePartnerType type;
  final String? tagline;
  final String? heroImageUrl;
  final String? logoImageUrl;
}

enum InvitePartnerType {
  mercadoProducer,
}
