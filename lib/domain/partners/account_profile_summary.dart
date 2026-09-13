export 'account_profile_taxonomy_term.dart';
export 'account_profile_taxonomy_terms.dart';

import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/account_profile.dart';
import 'package:belluga_now/domain/partners/account_profile_gallery_group.dart';
import 'package:belluga_now/domain/partners/account_profile_taxonomy_terms.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_text_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

class AccountProfileSummary extends AccountProfile {
  AccountProfileSummary({
    required this.idValue,
    required this.nameValue,
    required this.profileTypeValue,
    this.partyTypeValue,
    this.slugValue,
    this.avatarValue,
    this.coverValue,
    this.taglineValue,
    this.bioValue,
    List<AccountProfileGalleryGroup>? galleryGroupValues,
    List<AccountProfileTagValue>? tagValues,
    AccountProfileTaxonomyTerms? taxonomyTerms,
    this.locationAddressValue,
    this.locationLatitudeValue,
    this.locationLongitudeValue,
    DomainBooleanValue? supportsPublicNavigationValue,
    super.canOpenPublicDetailValue,
    super.publicDetailPathValue,
  }) : galleryGroupValues = List<AccountProfileGalleryGroup>.unmodifiable(
         galleryGroupValues ?? const <AccountProfileGalleryGroup>[],
       ),
       tagValues = List<AccountProfileTagValue>.unmodifiable(
         tagValues ?? const <AccountProfileTagValue>[],
       ),
       taxonomyTerms =
           taxonomyTerms ?? const AccountProfileTaxonomyTerms.empty(),
       supportsPublicNavigationValue =
           supportsPublicNavigationValue ??
           (DomainBooleanValue(defaultValue: true, isRequired: false)
             ..parse('true'));

  final AccountProfileTextValue idValue;
  final AccountProfileNameValue nameValue;
  final SlugValue? slugValue;
  final AccountProfileTypeValue profileTypeValue;
  final AccountProfileTextValue? partyTypeValue;
  final ThumbUriValue? avatarValue;
  final ThumbUriValue? coverValue;
  final DescriptionValue? taglineValue;
  final DescriptionValue? bioValue;
  final List<AccountProfileGalleryGroup> galleryGroupValues;
  final List<AccountProfileTagValue> tagValues;
  final AccountProfileTaxonomyTerms taxonomyTerms;
  final AccountProfileLocationAddressValue? locationAddressValue;
  final LatitudeValue? locationLatitudeValue;
  final LongitudeValue? locationLongitudeValue;
  final DomainBooleanValue supportsPublicNavigationValue;

  String get id => idValue.value;
  String get name => nameValue.value;
  String get displayName => name;
  String get slug => slugValue?.value ?? '';
  String get profileType => profileTypeValue.value;
  String? get partyType {
    final value = partyTypeValue?.value.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String get type => profileType;
  String? get normalizedProfileType {
    final value = profileType.trim();
    return value.isEmpty ? null : value;
  }

  Uri? get avatarUri => avatarValue?.value;
  String? get avatarUrl => avatarUri?.toString();
  Uri? get coverUri => coverValue?.value;
  String? get coverUrl => coverUri?.toString();
  String? get tagline {
    final value = taglineValue?.value.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get bio {
    final value = bioValue?.value.trim();
    return value == null || value.isEmpty ? null : value;
  }

  List<AccountProfileGalleryGroup> get galleryGroups =>
      List<AccountProfileGalleryGroup>.unmodifiable(galleryGroupValues);
  List<AccountProfileTagValue> get tags =>
      List<AccountProfileTagValue>.unmodifiable(tagValues);
  String? get locationAddress {
    final value = locationAddressValue?.value.trim();
    return value == null || value.isEmpty ? null : value;
  }

  double? get locationLat => locationLatitudeValue?.value;
  double? get locationLng => locationLongitudeValue?.value;
  bool get hasLocationCoordinates => locationLat != null && locationLng != null;
  bool get supportsPublicNavigation => supportsPublicNavigationValue.value;
}
