import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

/// Lightweight Partner projection for event contexts (venue, participants)
/// Similar to InvitePartnerSummary but for events
class PartnerResume {
  PartnerResume({
    required this.idValue,
    required this.nameValue,
    this.slugValue,
    required this.type,
    InvitePartnerTaglineValue? taglineValue,
    InvitePartnerHeroImageValue? heroImageValue,
    InvitePartnerLogoImageValue? logoImageValue,
  })  : taglineValue = taglineValue ?? InvitePartnerTaglineValue(),
        heroImageValue = heroImageValue ?? InvitePartnerHeroImageValue(),
        logoImageValue = logoImageValue ?? InvitePartnerLogoImageValue();

  final MongoIDValue idValue;
  final InvitePartnerNameValue nameValue;
  final SlugValue? slugValue;
  final InvitePartnerType type;
  final InvitePartnerTaglineValue taglineValue;
  final InvitePartnerHeroImageValue heroImageValue;
  final InvitePartnerLogoImageValue logoImageValue;

  String get displayName => nameValue.value;
  String? get slug => slugValue?.value;

  String? get tagline {
    final value = taglineValue.value;
    return value.isEmpty ? null : value;
  }

  Uri? get heroImageUri => heroImageValue.value;
  Uri? get logoImageUri => logoImageValue.value;
  String? get heroImageUrl => heroImageUri?.toString();
  String? get logoImageUrl => logoImageUri?.toString();

  factory PartnerResume.fromDto(Map<String, dynamic> dto) {
    SlugValue? slugValue;
    final slug = dto['slug']?.toString();
    if (slug != null && slug.isNotEmpty) {
      slugValue = SlugValue()..parse(slug);
    }
    return PartnerResume(
      idValue: MongoIDValue()..parse(dto['id'] ?? ''),
      nameValue: InvitePartnerNameValue()..parse(dto['display_name'] ?? ''),
      slugValue: slugValue,
      type: InvitePartnerType
          .mercadoProducer, // TODO: Expand enum or use string when Partner types are defined
      taglineValue: dto['tagline'] != null
          ? (InvitePartnerTaglineValue()..parse(dto['tagline']))
          : null,
      logoImageValue: dto['logo_url'] != null
          ? (InvitePartnerLogoImageValue()..parse(dto['logo_url']))
          : null,
      heroImageValue: dto['hero_image_url'] != null
          ? (InvitePartnerHeroImageValue()..parse(dto['hero_image_url']))
          : null,
    );
  }
}
