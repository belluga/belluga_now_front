import 'dart:async';

import 'package:belluga_now/application/functions/today.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_item_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ScheduleScreenController implements Disposable {
  ScheduleScreenController({
    ScheduleRepositoryContract? scheduleRepository,
  }) : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>() {
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

  final eventsStreamValue = StreamValue<List<VenueEventResume>?>();
  late final StreamSubscription<List<DateTime>> _visibleDatesSubscription;
  late final StreamSubscription<List<DateTime>> _invisibleDatesSubscription;

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
    await _getEvents(date: Today.today);
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

  @override
  void onDispose() {
    scrollController.dispose();
    selectedDateStreamValue.dispose();
    firsVisibleDateStreamValue.dispose();
    visibleDatesStreamValue.dispose();
    invisibleDatesStreamValue.dispose();
    eventsStreamValue.dispose();
    isTodayVisible.dispose();
    scheduleSummaryStreamValue.dispose();
    _visibleDatesSubscription.cancel();
    _invisibleDatesSubscription.cancel();
  }
}
