part of '../partner_profile_module_data.dart';

typedef PartnerSupportedEntityTitle = String;
typedef PartnerSupportedEntityThumb = String;

class PartnerSupportedEntityView {
  const PartnerSupportedEntityView({
    required this.title,
    this.thumb,
  });

  final PartnerSupportedEntityTitle title;
  final PartnerSupportedEntityThumb? thumb;
}
