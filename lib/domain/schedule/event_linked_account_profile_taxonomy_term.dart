import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';

class EventLinkedAccountProfileTaxonomyTerm {
  EventLinkedAccountProfileTaxonomyTerm({
    required this.typeValue,
    required this.valueValue,
    required this.nameValue,
    AccountProfileTagValue? taxonomyNameValue,
    AccountProfileTagValue? compatibilityLabelValue,
  })  : taxonomyNameValue = taxonomyNameValue ?? AccountProfileTagValue(''),
        compatibilityLabelValue =
            compatibilityLabelValue ?? AccountProfileTagValue('');

  final AccountProfileTagValue typeValue;
  final AccountProfileTagValue valueValue;
  final AccountProfileTagValue nameValue;
  final AccountProfileTagValue taxonomyNameValue;
  final AccountProfileTagValue compatibilityLabelValue;

  AccountProfileTagValue get labelValue => nameValue.value.trim().isNotEmpty
      ? nameValue
      : (compatibilityLabelValue.value.trim().isNotEmpty
          ? compatibilityLabelValue
          : valueValue);
}
