import 'package:belluga_now/infrastructure/dal/dao/backend_routing_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BackendRoutingPolicy resolves all domains to live source', () {
    const policy = BackendRoutingPolicy();

    for (final domain in BackendDomain.values) {
      expect(policy.resolve(domain), BackendSource.live);
    }
  });
}
