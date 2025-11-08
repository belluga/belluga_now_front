import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';

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
  InvitePartnerSummary({
    required this.id,
    required this.nameValue,
    required this.type,
    InvitePartnerTaglineValue? taglineValue,
    InvitePartnerHeroImageValue? heroImageValue,
    InvitePartnerLogoImageValue? logoImageValue,
  })  : taglineValue = taglineValue ?? InvitePartnerTaglineValue(),
        heroImageValue = heroImageValue ?? InvitePartnerHeroImageValue(),
        logoImageValue = logoImageValue ?? InvitePartnerLogoImageValue();

  final String id;
  final InvitePartnerNameValue nameValue;
  final InvitePartnerType type;
  final InvitePartnerTaglineValue taglineValue;
  final InvitePartnerHeroImageValue heroImageValue;
  final InvitePartnerLogoImageValue logoImageValue;

  String get name => nameValue.value;

  String? get tagline {
    final value = taglineValue.value;
    return value.isEmpty ? null : value;
  }

  Uri? get heroImageUri => heroImageValue.value;

  Uri? get logoImageUri => logoImageValue.value;

  String? get heroImageUrl => heroImageUri?.toString();

  String? get logoImageUrl => logoImageUri?.toString();
}

enum InvitePartnerType {
  mercadoProducer,
}
