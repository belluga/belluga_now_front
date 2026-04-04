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

  String get type => typeValue.value;
  String get value => valueValue.value;
  String get name => nameValue.value;
  String get label => name.trim().isNotEmpty ? name.trim() : value.trim();
}
