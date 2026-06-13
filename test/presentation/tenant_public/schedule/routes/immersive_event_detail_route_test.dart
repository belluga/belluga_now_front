import 'package:belluga_now/presentation/tenant_public/schedule/routes/immersive_event_detail_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'immersive event detail route resolver params preserve occurrence query for canonical detail hydration',
      () {
    const route = ImmersiveEventDetailRoutePage(
      eventSlug: 'pw-event-share-boundary-store-release',
      occurrenceId: 'occ-2',
      tab: 'programming',
    );

    expect(route.resolverParams, {
      'slug': 'pw-event-share-boundary-store-release',
      'occurrence': 'occ-2',
    });
  });
}
