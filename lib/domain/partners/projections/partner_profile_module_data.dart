class PartnerEventView {
  const PartnerEventView({
    required this.title,
    required this.date,
    required this.location,
  });

  final String title;
  final String date;
  final String location;
}

class PartnerProductView {
  const PartnerProductView({
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  final String title;
  final String price;
  final String imageUrl;
}

class PartnerMediaView {
  const PartnerMediaView({
    required this.url,
    this.title,
  });

  final String url;
  final String? title;
}

class PartnerFaqView {
  const PartnerFaqView({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

class PartnerLocationView {
  const PartnerLocationView({
    required this.address,
    required this.status,
    this.lat,
    this.lng,
  });

  final String address;
  final String status;
  final String? lat;
  final String? lng;
}

class PartnerScoreView {
  const PartnerScoreView({
    required this.invites,
    required this.presences,
  });

  final String invites;
  final String presences;
}

class PartnerSupportedEntityView {
  const PartnerSupportedEntityView({
    required this.title,
    this.thumb,
  });

  final String title;
  final String? thumb;
}

class PartnerLinkView {
  const PartnerLinkView({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String icon;
}

class PartnerExperienceView {
  const PartnerExperienceView({
    required this.title,
    required this.duration,
    required this.price,
  });

  final String title;
  final String duration;
  final String price;
}

class PartnerRecommendationView {
  const PartnerRecommendationView({
    required this.title,
    required this.type,
  });

  final String title;
  final String type;
}
