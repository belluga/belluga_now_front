export 'backend_domain.dart';
export 'backend_source.dart';

import 'package:flutter/foundation.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_domain.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_source.dart';

class BackendRoutingPolicy {
  const BackendRoutingPolicy({
    this.appData = BackendSource.live,
    this.tenant = BackendSource.live,
    this.accountProfiles = BackendSource.live,
    this.schedule = BackendSource.live,
  });

  final BackendSource appData;
  final BackendSource tenant;
  final BackendSource accountProfiles;
  final BackendSource schedule;

  BackendSource resolve(BackendDomain domain) {
    if (kReleaseMode) {
      return BackendSource.live;
    }
    switch (domain) {
      case BackendDomain.appData:
        return appData;
      case BackendDomain.tenant:
        return tenant;
      case BackendDomain.accountProfiles:
        return accountProfiles;
      case BackendDomain.schedule:
        return schedule;
    }
  }
}
