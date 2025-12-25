import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_provisional_screen/controllers/tenant_home_provisional_controller.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

import 'tenant_home_provisional_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<TenantHomeController>(),
])
void main() {
  late TenantHomeProvisionalController controller;
  late MockTenantHomeController mockHomeController;
  late StreamValue<List<VenueEventResume>> myEventsStreamValue;

  setUp(() {
    mockHomeController = MockTenantHomeController();
    myEventsStreamValue =
        StreamValue<List<VenueEventResume>>(defaultValue: const []);

    // Stub Home Controller streams
    when(mockHomeController.userAddressStreamValue)
        .thenReturn(StreamValue<String?>());
    when(mockHomeController.confirmedIdsStream)
        .thenReturn(StreamValue<Set<String>>(defaultValue: {}));
    when(mockHomeController.pendingInvitesStreamValue)
        .thenReturn(StreamValue<List<InviteModel>>(defaultValue: []));
    when(mockHomeController.myEventsStreamValue)
        .thenReturn(myEventsStreamValue);

     // Stub init methods
    when(mockHomeController.init()).thenAnswer((_) async {});

    controller = TenantHomeProvisionalController(
      homeController: mockHomeController,
    );
  });

  tearDown(() {
    controller.onDispose();
  });

  test('init initializes dependencies', () async {
    await controller.init();

    verify(mockHomeController.init()).called(1);
  });

  test('filters my events to confirmed and upcoming', () async {
    final now = DateTime.now();
    final upcomingEvent = VenueEventResume(
      id: '1',
      slug: 'slug-1',
      titleValue: TitleValue()..parse('Upcoming Event Title Long Enough'),
      imageUriValue: ThumbUriValue(defaultValue: Uri.parse('http://example.com/img.jpg')),
      startDateTimeValue: DateTimeValue(defaultValue: now.add(const Duration(hours: 1))),
      locationValue: DescriptionValue()..parse('Valid Location Name Long Enough'),
      artists: [],
      tags: [],
    );
    final pastEvent = VenueEventResume(
      id: '2',
      slug: 'slug-2',
      titleValue: TitleValue()..parse('Past Event Title Long Enough'),
      imageUriValue: ThumbUriValue(defaultValue: Uri.parse('http://example.com/img.jpg')),
      startDateTimeValue: DateTimeValue(defaultValue: now.subtract(const Duration(days: 1))),
      locationValue: DescriptionValue()..parse('Valid Location Name Long Enough'),
      artists: [],
      tags: [],
    );

    when(mockHomeController.myEventsStreamValue)
        .thenReturn(myEventsStreamValue);

    await controller.init(); // Starts listening
    
    // Simulate stream update
    myEventsStreamValue.addValue([upcomingEvent, pastEvent]);
    await pumpEventQueue();
    
    expect(
      controller.myEventsFilteredStreamValue.value.map((e) => e.id),
      contains('1'),
    );
     expect(
      controller.myEventsFilteredStreamValue.value.map((e) => e.id),
      isNot(contains('2')),
    );
  });
}
