export 'value_objects/paged_account_profiles_result_values.dart';

import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class PagedAccountProfilesResult {
  PagedAccountProfilesResult({
    required this.profiles,
    required this.hasMoreValue,
    this.discoveryFilterFacets,
    this.discoveryFilterCatalog,
  });

  final List<AccountProfileModel> profiles;
  final DomainBooleanValue hasMoreValue;
  final DiscoveryFilterRuntimeFacets? discoveryFilterFacets;
  final DiscoveryFilterCatalog? discoveryFilterCatalog;

  bool get hasMore => hasMoreValue.value;
}
