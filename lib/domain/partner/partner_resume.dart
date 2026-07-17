import 'package:belluga_now/domain/invites/invite_partner_type.dart';
import 'package:belluga_now/domain/partners/account_profile_gallery_group.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_public_detail_path_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_hero_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_logo_image_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_name_value.dart';
import 'package:belluga_now/domain/partner/value_objects/invite_partner_tagline_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

/// Lightweight Partner projection for event contexts (venue, artists)
/// Similar to InvitePartnerSummary but for events
class PartnerResume {
  PartnerResume({
    required this.idValue,
    required this.nameValue,
    this.slugValue,
    required this.type,
    AccountProfileTypeValue? profileTypeValue,
    DomainBooleanValue? canOpenPublicDetailValue,
    AccountProfilePublicDetailPathValue? publicDetailPathValue,
    InvitePartnerTaglineValue? taglineValue,
    InvitePartnerHeroImageValue? heroImageValue,
    InvitePartnerLogoImageValue? logoImageValue,
    DescriptionValue? bioValue,
    List<AccountProfileGalleryGroup>? galleryGroupValues,
    List<AccountProfileTagValue>? taxonomyLabelValues,
    DomainBooleanValue? supportsPublicNavigationValue,
  }) : profileTypeValue = profileTypeValue ?? AccountProfileTypeValue(),
       taglineValue = taglineValue ?? InvitePartnerTaglineValue(),
       canOpenPublicDetailValue =
           canOpenPublicDetailValue ??
           (DomainBooleanValue(defaultValue: false, isRequired: false)
             ..parse('false')),
       publicDetailPathValue =
           publicDetailPathValue ?? AccountProfilePublicDetailPathValue(),
       heroImageValue = heroImageValue ?? InvitePartnerHeroImageValue(),
       logoImageValue = logoImageValue ?? InvitePartnerLogoImageValue(),
       bioValue = bioValue ?? DescriptionValue(defaultValue: '', minLenght: 0),
       galleryGroupValues = List<AccountProfileGalleryGroup>.unmodifiable(
         galleryGroupValues ?? const <AccountProfileGalleryGroup>[],
       ),
       taxonomyLabelValues = List<AccountProfileTagValue>.unmodifiable(
         (taxonomyLabelValues ?? const <AccountProfileTagValue>[])
             .where((label) => label.value.trim().isNotEmpty),
       ),
       supportsPublicNavigationValue =
           supportsPublicNavigationValue ??
           (DomainBooleanValue(defaultValue: true, isRequired: false)
             ..parse('true'));

  final MongoIDValue idValue;
  final InvitePartnerNameValue nameValue;
  final SlugValue? slugValue;
  final InviteAccountProfileType type;
  final AccountProfileTypeValue profileTypeValue;
  final DomainBooleanValue canOpenPublicDetailValue;
  final AccountProfilePublicDetailPathValue publicDetailPathValue;
  final InvitePartnerTaglineValue taglineValue;
  final InvitePartnerHeroImageValue heroImageValue;
  final InvitePartnerLogoImageValue logoImageValue;
  final DescriptionValue bioValue;
  final List<AccountProfileGalleryGroup> galleryGroupValues;
  final List<AccountProfileTagValue> taxonomyLabelValues;
  final DomainBooleanValue supportsPublicNavigationValue;

  String get id => idValue.value;
  String get displayName => nameValue.value;
  String? get slug => slugValue?.value;
  String? get normalizedProfileType {
    final value = profileTypeValue.value.trim();
    return value.isEmpty ? null : value;
  }

  bool get canOpenPublicDetail => canOpenPublicDetailValue.value;
  String? get publicDetailPath {
    final value = publicDetailPathValue.value.trim();
    return value.isEmpty ? null : value;
  }

  String? get tagline {
    final value = taglineValue.value;
    return value.isEmpty ? null : value;
  }

  Uri? get heroImageUri => heroImageValue.value;
  Uri? get logoImageUri => logoImageValue.value;
  String? get heroImageUrl => heroImageUri?.toString();
  String? get logoImageUrl => logoImageUri?.toString();
  String? get bio {
    final value = bioValue.value.trim();
    return value.isEmpty ? null : value;
  }

  List<AccountProfileGalleryGroup> get galleryGroups =>
      List<AccountProfileGalleryGroup>.unmodifiable(galleryGroupValues);
  List<AccountProfileTagValue> get taxonomyLabels =>
      List<AccountProfileTagValue>.unmodifiable(taxonomyLabelValues);
  bool get supportsPublicNavigation => supportsPublicNavigationValue.value;
}
