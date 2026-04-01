import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_partner_summary_id_value.dart';

class InvitePartnerSummary {
  InvitePartnerSummary({
    required this.idValue,
    required this.nameValue,
    required this.type,
    InvitePartnerTaglineValue? taglineValue,
    InvitePartnerHeroImageValue? heroImageValue,
    InvitePartnerLogoImageValue? logoImageValue,
  })  : taglineValue = taglineValue ?? InvitePartnerTaglineValue(),
        heroImageValue = heroImageValue ?? InvitePartnerHeroImageValue(),
        logoImageValue = logoImageValue ?? InvitePartnerLogoImageValue();

  final InvitePartnerSummaryIdValue idValue;
  final InvitePartnerNameValue nameValue;
  final InviteAccountProfileType type;
  final InvitePartnerTaglineValue taglineValue;
  final InvitePartnerHeroImageValue heroImageValue;
  final InvitePartnerLogoImageValue logoImageValue;

  String get id => idValue.value;
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
