import 'package:belluga_now/domain/partners/value_objects/account_profile_public_detail_path_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

abstract class AccountProfile {
  AccountProfile({
    DomainBooleanValue? canOpenPublicDetailValue,
    this.publicDetailPathValue,
  }) : canOpenPublicDetailValue =
           canOpenPublicDetailValue ??
           (DomainBooleanValue(defaultValue: false, isRequired: false)
             ..parse('false'));

  final DomainBooleanValue canOpenPublicDetailValue;
  final AccountProfilePublicDetailPathValue? publicDetailPathValue;

  bool get canOpenPublicDetail => canOpenPublicDetailValue.value;

  String? get publicDetailPath {
    final value = publicDetailPathValue?.value.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get publicDetailUrl {
    if (!canOpenPublicDetail) {
      return null;
    }
    return publicDetailPath;
  }
}
