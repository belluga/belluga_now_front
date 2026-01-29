import 'package:flutter/foundation.dart';

enum BackendSource { live, mock }

enum BackendDomain { appData, tenant, partners, schedule }

class BackendRoutingPolicy {
  const BackendRoutingPolicy({
    this.appData = BackendSource.live,
    this.tenant = BackendSource.live,
    this.partners = BackendSource.live,
    this.schedule = BackendSource.live,
  });

  final BackendSource appData;
  final BackendSource tenant;
  final BackendSource partners;
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
      case BackendDomain.partners:
        return partners;
      case BackendDomain.schedule:
        return schedule;
    }
  }
}
