import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class PagedAccountProfilesResult {
  PagedAccountProfilesResult({
    required this.profiles,
    required Object hasMore,
  }) : hasMoreValue = _parseHasMore(hasMore);

  final List<AccountProfileModel> profiles;
  final DomainBooleanValue hasMoreValue;

  bool get hasMore => hasMoreValue.value;

  static DomainBooleanValue _parseHasMore(Object raw) {
    if (raw is DomainBooleanValue) {
      return raw;
    }
    final value = DomainBooleanValue();
    value.parse(raw.toString());
    return value;
  }
}
