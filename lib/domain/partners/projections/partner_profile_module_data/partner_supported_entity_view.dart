part of '../partner_profile_module_data.dart';

class PartnerSupportedEntityView {
  PartnerSupportedEntityView({
    this.idValue,
    required this.titleValue,
    this.thumbValue,
  });

  final MongoIDValue? idValue;
  final PartnerProjectionRequiredTextValue titleValue;
  final PartnerProjectionOptionalTextValue? thumbValue;

  String? get id {
    final value = idValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String get title => titleValue.value;
  String? get thumb => thumbValue?.value;
}
