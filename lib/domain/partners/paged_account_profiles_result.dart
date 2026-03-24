import 'package:belluga_now/domain/partners/account_profile_model.dart';

typedef HasMoreProfilesFlag = bool;

class PagedAccountProfilesResult {
  const PagedAccountProfilesResult({
    required this.profiles,
    required this.hasMore,
  });

  final List<AccountProfileModel> profiles;
  final HasMoreProfilesFlag hasMore;
}
