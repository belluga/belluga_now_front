import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:flutter_test/flutter_test.dart';

class IntegrationTestBootstrap {
  static void ensureNonProductionLandlordDomain() {
    const allowProduction =
        bool.fromEnvironment('ALLOW_PROD_LANDLORD', defaultValue: false);
    if (allowProduction) {
      return;
    }

    final domain = BellugaConstants.landlordDomain;
    if (domain == 'belluga.app') {
      fail(
        'Integration tests must not run against production landlord domain. '
        'Pass --dart-define-from-file=config/defines/local.override.json '
        'or provide explicit '
        '--dart-define=LANDLORD_DOMAIN=<local-domain> '
        'with --dart-define=API_SCHEME=http. '
        'If you explicitly need production, pass '
        '--dart-define=ALLOW_PROD_LANDLORD=true.',
      );
    }
  }
}
