part of '../partner_profile_module_data.dart';

typedef PartnerEventTitle = String;
typedef PartnerEventDate = String;
typedef PartnerEventLocation = String;

class PartnerEventView {
  const PartnerEventView({
    required this.title,
    required this.date,
    required this.location,
  });

  final PartnerEventTitle title;
  final PartnerEventDate date;
  final PartnerEventLocation location;
}
