import 'dart:async';

import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant/home/screens/tenant_home_screen/controllers/tenant_home_controller.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;
import 'package:stream_value/core/stream_value.dart';

class TenantHomeProvisionalController implements Disposable {
  TenantHomeProvisionalController({
    TenantHomeController? homeController,
  })  : _homeController =
            homeController ?? GetIt.I.get<TenantHomeController>();

  static const Duration _assumedEventDuration = Duration(hours: 3);

  final TenantHomeController _homeController;

  final StreamValue<List<VenueEventResume>> myEventsFilteredStreamValue =
      StreamValue<List<VenueEventResume>>(defaultValue: const []);

  StreamValue<String?> get userAddressStreamValue =>
      _homeController.userAddressStreamValue;
  StreamValue<Set<String>> get confirmedIdsStreamValue =>
      _homeController.confirmedIdsStream;
  StreamValue<List<InviteModel>> get pendingInvitesStreamValue =>
      _homeController.pendingInvitesStreamValue;

  StreamSubscription? _myEventsSubscription;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _homeController.init();

    _listenMyEvents();
  }

  void _listenMyEvents() {
    _myEventsSubscription?.cancel();
    _myEventsSubscription =
        _homeController.myEventsStreamValue.stream.listen(_updateMyEvents);
    _updateMyEvents(_homeController.myEventsStreamValue.value);
  }

  void _updateMyEvents(List<VenueEventResume> events) {
    myEventsFilteredStreamValue.addValue(_filterConfirmedUpcoming(events));
  }

  List<VenueEventResume> _filterConfirmedUpcoming(
    List<VenueEventResume> events,
  ) {
    final now = DateTime.now();
    return events.where((event) {
      final start = event.startDateTime;
      if (!start.isAfter(now)) {
        final end = start.add(_assumedEventDuration);
        return now.isBefore(end);
      }
      return true;
    }).toList();
  }

  String? firstMyEventSlug() {
    final events = myEventsFilteredStreamValue.value;
    if (events.isEmpty) return null;
    return events.first.slug;
  }

  String? distanceLabelForMyEvent(VenueEventResume event) =>
      _homeController.distanceLabelFor(event);

  @override
  void onDispose() {
    myEventsFilteredStreamValue.dispose();
    _myEventsSubscription?.cancel();
  }
}
