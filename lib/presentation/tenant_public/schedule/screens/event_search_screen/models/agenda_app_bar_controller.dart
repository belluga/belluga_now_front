import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AgendaAppBarController {
  StreamValue<bool> get searchActiveStreamValue;
  TextEditingController get searchController;
  FocusNode get focusNode;
  void toggleSearchMode();
  Future<void> searchEvents(String query);
  StreamValue<double> get maxRadiusMetersStreamValue;
  StreamValue<double> get radiusMetersStreamValue;
  void setRadiusMeters(double meters);
  StreamValue<InviteFilter> get inviteFilterStreamValue;
  void cycleInviteFilter();
  StreamValue<bool> get showHistoryStreamValue;
  void toggleHistory();
}
