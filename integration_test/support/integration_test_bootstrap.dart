import 'dart:developer' as developer;

import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:flutter_test/flutter_test.dart';

class IntegrationTestBootstrap {
  static bool _vmGoldenComparatorStreamSeeded = false;

  static void ensureNonProductionLandlordDomain() {
    _ensureVmGoldenComparatorStream();

    const allowProduction =
        bool.fromEnvironment('ALLOW_PROD_LANDLORD', defaultValue: false);
    if (allowProduction) {
      return;
    }

    final domain = BellugaConstants.landlordDomain;
    if (domain == 'booraagora.com.br') {
      fail(
        'Integration tests must not run against production landlord domain. '
        'Pass --dart-define-from-file=config/defines/local.override.json '
        'or provide explicit '
        '--dart-define=LANDLORD_DOMAIN=<local-domain>. '
        'If you explicitly need production, pass '
        '--dart-define=ALLOW_PROD_LANDLORD=true.',
      );
    }
  }

  static void _ensureVmGoldenComparatorStream() {
    if (_vmGoldenComparatorStreamSeeded) {
      return;
    }

    // Flutter tooling listens to this custom VM stream for integration golden
    // compatibility. Seed it once per test process so all integration files
    // share the same startup behavior.
    developer.postEvent(
      'integration_test.VmServiceProxyGoldenFileComparator',
      const <String, Object>{},
    );
    _vmGoldenComparatorStreamSeeded = true;
  }
}
