import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/partner/partner_resume.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

mixin PartnerDtoMapper {
  PartnerResume mapPartnerResume(Map<String, dynamic> dto) {
    SlugValue? slugValue;
    final slug = dto['slug']?.toString();
    if (slug != null && slug.isNotEmpty) {
      slugValue = SlugValue()..parse(slug);
    }

    InvitePartnerTaglineValue? taglineValue;
    final tagline = dto['tagline']?.toString();
    if (tagline != null && tagline.isNotEmpty) {
      taglineValue = InvitePartnerTaglineValue()..parse(tagline);
    }

    InvitePartnerLogoImageValue? logoImageValue;
    final logoUrl = dto['logo_url']?.toString();
    if (logoUrl != null && logoUrl.isNotEmpty) {
      logoImageValue = InvitePartnerLogoImageValue()..parse(logoUrl);
    }

    InvitePartnerHeroImageValue? heroImageValue;
    final heroUrl = dto['hero_image_url']?.toString();
    if (heroUrl != null && heroUrl.isNotEmpty) {
      heroImageValue = InvitePartnerHeroImageValue()..parse(heroUrl);
    }

    return PartnerResume(
      idValue: MongoIDValue()..parse(dto['id']?.toString() ?? ''),
      nameValue: InvitePartnerNameValue()
        ..parse(dto['display_name']?.toString() ?? ''),
      slugValue: slugValue,
      type: InviteAccountProfileType.mercadoProducer,
      taglineValue: taglineValue,
      logoImageValue: logoImageValue,
      heroImageValue: heroImageValue,
    );
  }
}
