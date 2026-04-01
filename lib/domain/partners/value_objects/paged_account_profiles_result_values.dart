import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

PagedAccountProfilesResult pagedAccountProfilesResultFromRaw({
  required List<AccountProfileModel> profiles,
  required Object? hasMore,
}) {
  final hasMoreValue = DomainBooleanValue();
  hasMoreValue.parse(hasMore.toString());
  return PagedAccountProfilesResult(
    profiles: profiles,
    hasMoreValue: hasMoreValue,
  );
}
