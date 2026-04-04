import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';

class EventLinkedAccountProfileTaxonomyTerm {
  EventLinkedAccountProfileTaxonomyTerm({
    required this.typeValue,
    required this.valueValue,
    required this.nameValue,
  });

  final AccountProfileTagValue typeValue;
  final AccountProfileTagValue valueValue;
  final AccountProfileTagValue nameValue;

  AccountProfileTagValue get labelValue =>
      nameValue.value.trim().isNotEmpty ? nameValue : valueValue;
}
