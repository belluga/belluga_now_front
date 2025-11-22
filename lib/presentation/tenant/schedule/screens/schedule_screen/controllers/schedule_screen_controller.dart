import 'dart:async';

import 'package:belluga_now/application/functions/today.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_item_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ScheduleScreenController implements Disposable {
  ScheduleScreenController({
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsRepositoryContract? userEventsRepository,
    InvitesRepositoryContract? invitesRepository,
  })  : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>() {
    _visibleDatesSubscription = visibleDatesStreamValue.stream.listen((dates) {
      updateCurrentMonth(dates);
      todayBecomeVisible(dates);
    });
    _invisibleDatesSubscription =
        invisibleDatesStreamValue.stream.listen((dates) {
      updateCurrentMonth(dates);
      todayBecomeInvisible(dates);
    });
  }

  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;
  final InvitesRepositoryContract _invitesRepository;

  final eventsStreamValue = StreamValue<List<VenueEventResume>?>();
  final allEventsStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const []);
  late final StreamSubscription<List<DateTime>> _visibleDatesSubscription;
  late final StreamSubscription<List<DateTime>> _invisibleDatesSubscription;
  StreamSubscription? _confirmedEventsSubscription;
  StreamSubscription? _pendingInvitesSubscription;

  final scrollController = ScrollController();

  final isTodayVisible = StreamValue<bool>(defaultValue: true);

  final selectedDateStreamValue =
      StreamValue<DateTime>(defaultValue: Today.today);

  final firsVisibleDateStreamValue =
      StreamValue<DateTime>(defaultValue: Today.today);

  final visibleDatesStreamValue = StreamValue<List<DateTime>>(defaultValue: []);

  final invisibleDatesStreamValue =
      StreamValue<List<DateTime>>(defaultValue: []);

  final scheduleSummaryStreamValue = StreamValue<ScheduleSummaryModel?>();

  int get initialIndex => scheduleSummaryStreamValue.value!.initialIndex;

  int get totalItems => scheduleSummaryStreamValue.value!.totalItems;

  DateTime get firstDayRange => scheduleSummaryStreamValue.value!.firstDayRange;

  DateTime get lastDayRange => scheduleSummaryStreamValue.value!.lastDayRange;

  Future<void> init() async {
    await _getScheduleSummary();
  }

  Future<void> _getEvents({DateTime? date}) async {
    date ??= Today.today;
    eventsStreamValue.addValue(null);
    final events = await _scheduleRepository.getEventResumesByDate(date);
    eventsStreamValue.addValue(events);
  }

  Future<void> _getScheduleSummary() async {
    final ScheduleSummaryModel _scheduleSummary =
        await _scheduleRepository.getScheduleSummary();
    scheduleSummaryStreamValue.addValue(_scheduleSummary);

    // Cache all events for marker counting
    final events = await _scheduleRepository.getAllEvents();
    allEventsStreamValue.addValue(events);

    await _getEvents(date: Today.today);

    // Listen to confirmed events changes and refresh allEventsStreamValue to trigger UI update
    _confirmedEventsSubscription?.cancel();
    _confirmedEventsSubscription =
        _userEventsRepository.confirmedEventIdsStream.stream.listen((_) {
      // Re-emit the same value to trigger StreamValueBuilder in DateItem
      allEventsStreamValue.addValue(allEventsStreamValue.value);
    });

    // Listen to pending invites changes
    _pendingInvitesSubscription?.cancel();
    _pendingInvitesSubscription =
        _invitesRepository.pendingInvitesStreamValue.stream.listen((_) {
      allEventsStreamValue.addValue(allEventsStreamValue.value);
    });
  }

  void selectDate(DateTime date) {
    selectedDateStreamValue.addValue(date);
    _getEvents(date: date);
  }

  void becomeVisible(DateTime date) {
    final List<DateTime> _dates = visibleDatesStreamValue.value;
    _dates.add(date);
    _dates.sort((a, b) => a.compareTo(b));
    visibleDatesStreamValue.addValue(_dates);
  }

  void becomeInvisible(DateTime date) {
    final List<DateTime> _dates = invisibleDatesStreamValue.value;
    _dates.add(date);
    _dates.sort((a, b) => a.compareTo(b));
    invisibleDatesStreamValue.addValue(_dates);
  }

  void todayBecomeInvisible(List<DateTime> invisibleDates) {
    final bool _becomeInvisible = invisibleDates.contains(Today.today);
    isTodayVisible.addValue(!_becomeInvisible);
  }

  void todayBecomeVisible(List<DateTime> visibleDates) {
    isTodayVisible.addValue(visibleDates.contains(Today.today));
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void updateCurrentMonth(List<DateTime> dates) {
    final List<DateTime> _visibleDates = visibleDatesStreamValue.value;
    final List<DateTime> _invisibleDates = invisibleDatesStreamValue.value;

    _visibleDates.removeWhere((element) => _invisibleDates.contains(element));
    _invisibleDates.clear();

    final _firstDate = _visibleDates.firstOrNull;
    firsVisibleDateStreamValue.addValue(_firstDate);
  }

  List<ScheduleSummaryItemModel> getEventsSummaryByDate(DateTime date) =>
      scheduleSummaryStreamValue.value!.items
          .where(
            (element) => isSameDay(element.dateTimeStart, date),
          )
          .toList();

  DateTime getDateByIndex(int index) =>
      Today.today.add(Duration(days: index - initialIndex));

  int getIndexByDate(DateTime date) =>
      initialIndex + (date.difference(Today.today).inDays);

  /// Count confirmed events for a specific date
  int getConfirmedEventsCountByDate(DateTime date) {
    final allEvents = allEventsStreamValue.value;

    // Filter events for this date that are confirmed
    return allEvents.where((event) {
      final eventDate = event.dateTimeStart.value;
      if (eventDate == null) return false;
      return isSameDay(eventDate, date) &&
          _userEventsRepository.isEventConfirmed(event.id.value);
    }).length;
  }

  /// Count pending invites for a specific date
  int getPendingInvitesCountByDate(DateTime date) {
    final allInvites = _invitesRepository.pendingInvitesStreamValue.value;
    return allInvites.where((invite) {
      final inviteDate = invite.eventDateValue.value;
      if (inviteDate == null) return false;

      // Check if this event is already confirmed
      final isConfirmed =
          _userEventsRepository.isEventConfirmed(invite.eventId);

      return isSameDay(inviteDate, date) && !isConfirmed;
    }).length;
  }

  @override
  void onDispose() {
    scrollController.dispose();
    selectedDateStreamValue.dispose();
    firsVisibleDateStreamValue.dispose();
    visibleDatesStreamValue.dispose();
    invisibleDatesStreamValue.dispose();
    eventsStreamValue.dispose();
    allEventsStreamValue.dispose();
    isTodayVisible.dispose();
    scheduleSummaryStreamValue.dispose();
    _visibleDatesSubscription.cancel();
    _invisibleDatesSubscription.cancel();
    _confirmedEventsSubscription?.cancel();
    _pendingInvitesSubscription?.cancel();
  }
}
