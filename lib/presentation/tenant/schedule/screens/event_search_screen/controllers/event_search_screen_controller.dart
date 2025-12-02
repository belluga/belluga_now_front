import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class EventSearchScreenController implements Disposable {
  EventSearchScreenController({
    ScheduleRepositoryContract? scheduleRepository,
  }) : _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>();

  final ScheduleRepositoryContract _scheduleRepository;

  final searchController = TextEditingController();
  final focusNode = FocusNode();

  final allEventsStreamValue = StreamValue<List<EventModel>?>();
  final availableEventsStreamValue = StreamValue<List<EventModel>?>();
  final searchResultsStreamValue = StreamValue<List<EventModel>?>();
  final showHistoryStreamValue = StreamValue<bool>(defaultValue: false);

  Future<void> init() async {
    await _populateAllEvents();
    _updateAvailableEvents();
  }

  Future<void> _populateAllEvents() async {
    final List<EventModel> _allEvents =
        await _scheduleRepository.getAllEvents();
    _allEvents.sort(
        (a, b) => a.dateTimeStart.value!.compareTo(b.dateTimeStart.value!));
    allEventsStreamValue.addValue(_allEvents);
  }

  void toggleHistory() {
    final currentValue = showHistoryStreamValue.value;
    showHistoryStreamValue.addValue(!currentValue);
    _updateAvailableEvents();
  }

  void _updateAvailableEvents() {
    final _showHistory = showHistoryStreamValue.value;

    if (_showHistory) {
      _makeAllEventsAvailable();
    } else {
      _makeOnlyFutureAvailable();
    }

    if (searchController.text.isNotEmpty) {
      _performSearch();
    } else {
      searchResultsStreamValue.addValue(availableEventsStreamValue.value);
    }
  }

  void _makeAllEventsAvailable() {
    availableEventsStreamValue.addValue(allEventsStreamValue.value);
  }

  void _makeOnlyFutureAvailable() {
    final now = DateTime.now();

    final filteredEvents = allEventsStreamValue.value
        ?.where((event) =>
            event.dateTimeStart.value!.isAfter(now) ||
            event.dateTimeStart.value!.isAtSameMomentAs(now))
        .toList();

    availableEventsStreamValue.addValue(filteredEvents);
  }

  void searchEvents(String query) {
    if (query.isEmpty) {
      searchResultsStreamValue.addValue([]);
      return;
    }

    _performSearch();
  }

  void _performSearch() {
    final _availableEvents = availableEventsStreamValue.value;

    final lowercaseQuery = searchController.text.toLowerCase();

    final filteredEvents = _availableEvents?.where((event) {
      final titleMatch =
          event.title.value.toLowerCase().contains(lowercaseQuery);
      final contentMatch =
          (event.content.value ?? "").toLowerCase().contains(lowercaseQuery);
      final artistMatch = event.artists.any(
        (artist) => artist.displayName.toLowerCase().contains(lowercaseQuery),
      );

      return titleMatch || contentMatch || artistMatch;
    }).toList();

    searchResultsStreamValue.addValue(filteredEvents);
  }

  @override
  void onDispose() {
    allEventsStreamValue.dispose();
    availableEventsStreamValue.dispose();
    searchResultsStreamValue.dispose();
    showHistoryStreamValue.dispose();
    focusNode.dispose();
    searchController.dispose();
  }
}
