import 'package:belluga_now/domain/invites/invite_partner_summary.dart';
import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class Partner {
  Partner({
    required this.idValue,
    required this.nameValue,
    required this.type,
    InvitePartnerTaglineValue? taglineValue,
    InvitePartnerHeroImageValue? heroImageValue,
    InvitePartnerLogoImageValue? logoImageValue,
  })  : taglineValue = taglineValue ?? InvitePartnerTaglineValue(),
        heroImageValue = heroImageValue ?? InvitePartnerHeroImageValue(),
        logoImageValue = logoImageValue ?? InvitePartnerLogoImageValue();

  final MongoIDValue idValue;
  final InvitePartnerNameValue nameValue;
  final InvitePartnerType type;
  final InvitePartnerTaglineValue taglineValue;
  final InvitePartnerHeroImageValue heroImageValue;
  final InvitePartnerLogoImageValue logoImageValue;

  String get displayName => nameValue.value;

  InvitePartnerSummary toInviteSummary() {
    final id = idValue.value;
    final fallback = idValue.defaultValue;
    final resolvedFallback = (() {
      if (fallback.isEmpty) {
        return '';
      }
      return fallback;
    })();
    return InvitePartnerSummary(
      id: id.isEmpty ? resolvedFallback : id,
      nameValue: nameValue,
      type: type,
      taglineValue: taglineValue,
      heroImageValue: heroImageValue,
      logoImageValue: logoImageValue,
    );
  }
}
