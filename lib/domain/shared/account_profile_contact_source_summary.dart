import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/shared/value_objects/account_profile_contact_source_account_profile_id_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class AccountProfileContactSourceSummary {
  AccountProfileContactSourceSummary({
    required this.idValue,
    required this.displayNameValue,
    this.slugValue,
    required this.profileTypeValue,
  });

  final AccountProfileContactSourceAccountProfileIdValue idValue;
  final TitleValue displayNameValue;
  final SlugValue? slugValue;
  final AccountProfileTypeValue profileTypeValue;

  String get id => idValue.value;
  String get displayName => displayNameValue.value;
  String? get slug {
    final raw = slugValue?.value.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  String get profileType => profileTypeValue.value;
}
