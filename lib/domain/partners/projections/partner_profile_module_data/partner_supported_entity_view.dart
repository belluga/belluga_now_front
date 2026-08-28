part of '../partner_profile_module_data.dart';

class PartnerSupportedEntityView {
  PartnerSupportedEntityView({
    this.idValue,
    required this.titleValue,
    this.thumbValue,
    this.profileTypeValue,
    this.partyTypeValue,
  });

  final MongoIDValue? idValue;
  final PartnerProjectionRequiredTextValue titleValue;
  final PartnerProjectionOptionalTextValue? thumbValue;
  final PartnerProjectionOptionalTextValue? profileTypeValue;
  final PartnerProjectionOptionalTextValue? partyTypeValue;

  String? get id {
    final value = idValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String get title => titleValue.value;
  String? get thumb => thumbValue?.value;
  String? get profileType => profileTypeValue?.value.trim();
  String? get partyType => partyTypeValue?.value.trim();
}
