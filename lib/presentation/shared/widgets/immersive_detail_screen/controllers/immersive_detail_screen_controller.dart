import 'dart:async';

import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class ImmersiveDetailScreenController {
  ImmersiveDetailScreenController({
    required this.tabItems,
    int initialTabIndex = 0,
    TelemetryRepositoryContract? telemetryRepository,
  }) : _telemetryRepository =
           telemetryRepository ??
           (GetIt.I.isRegistered<TelemetryRepositoryContract>()
               ? GetIt.I.get<TelemetryRepositoryContract>()
               : null),
       scrollController = ScrollController(),
       currentTabIndexStreamValue = StreamValue<int>(
         defaultValue: initialTabIndex,
       );

  final TelemetryRepositoryContract? _telemetryRepository;
  late final ScrollController scrollController;
  List<ImmersiveTabItem> tabItems;

  late final StreamValue<int> currentTabIndexStreamValue;

  bool _isProgrammaticScroll = false;
  int _programmaticScrollGeneration = 0;
  int? _lastSectionViewedIndex;
  Future<EventTrackerTimedEventHandle?>? _activeSectionTimedEventFuture;
  int? _activeSectionIndex;
  bool _disposed = false;
  final Set<int> _activatedTabIndexes = <int>{};

  void updateTabs(List<ImmersiveTabItem> updatedTabs) {
    if (_disposed) {
      return;
    }
    tabItems = updatedTabs;
    _activatedTabIndexes.clear();
    _lastSectionViewedIndex = null;

    if (tabItems.isEmpty) {
      _setCurrentTabIndex(0, track: false);
      return;
    }

    if (currentTabIndexStreamValue.value >= tabItems.length) {
      _setCurrentTabIndex(tabItems.length - 1, track: false);
      return;
    }

    _activateTabIfNeeded(currentTabIndexStreamValue.value, track: false);
  }

  void onTabBoundaryChanged(int index) {
    if (_disposed || _isProgrammaticScroll || index >= tabItems.length) {
      return;
    }
    _setCurrentTabIndex(index, track: true);
  }

  void onTabTapped(int index) {
    if (_disposed) {
      return;
    }
    if (index >= tabItems.length) return;

    _setCurrentTabIndex(index, track: true);

    final generation = ++_programmaticScrollGeneration;
    _isProgrammaticScroll = true;
    unawaited(
      _scrollToTab(index).whenComplete(() {
        if (!_disposed && generation == _programmaticScrollGeneration) {
          _isProgrammaticScroll = false;
        }
      }),
    );
  }

  Future<void> _scrollToTab(int index) {
    if (index == 0) {
      return !_disposed &&
              scrollController.hasClients &&
              scrollController.position.pixels > 0
          ? scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            )
          : Future<void>.value();
    }

    final targetContext = tabItems[index].key.currentContext;
    if (!_disposed && targetContext != null) {
      return Scrollable.ensureVisible(
        targetContext,
        alignment: 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
    return _scrollToTabAfterLayout(index);
  }

  Future<void> _scrollToTabAfterLayout(int index) async {
    await WidgetsBinding.instance.endOfFrame;
    if (_disposed || index >= tabItems.length) {
      return;
    }
    final targetContext = tabItems[index].key.currentContext;
    if (targetContext == null || !targetContext.mounted) {
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void ensureTabActivated(int index) {
    if (_disposed) {
      return;
    }
    _activateTabIfNeeded(index, track: false);
  }

  void onHorizontalSwipeEnd(double? primaryVelocity) {
    if (_disposed) {
      return;
    }
    if (primaryVelocity == null || primaryVelocity.abs() < 300) {
      return;
    }
    if (tabItems.length < 2) {
      return;
    }

    final delta = primaryVelocity < 0 ? 1 : -1;
    final targetIndex = (currentTabIndexStreamValue.value + delta).clamp(
      0,
      tabItems.length - 1,
    );
    if (targetIndex == currentTabIndexStreamValue.value) {
      return;
    }
    onTabTapped(targetIndex);
  }

  void dispose() {
    _disposed = true;
    _programmaticScrollGeneration += 1;
    _finishSectionTimedEvent();
    scrollController.dispose();
    currentTabIndexStreamValue.dispose();
  }

  void _setCurrentTabIndex(int index, {required bool track}) {
    if (_disposed) {
      return;
    }
    if (currentTabIndexStreamValue.value != index) {
      currentTabIndexStreamValue.addValue(index);
    }
    _activateTabIfNeeded(index, track: track);
  }

  void _activateTabIfNeeded(int index, {required bool track}) {
    if (index < 0 || index >= tabItems.length) {
      return;
    }

    if (_activatedTabIndexes.add(index)) {
      tabItems[index].onActivated?.call();
    }

    if (track) {
      _trackSectionViewed(index);
    }
  }

  void _trackSectionViewed(int index) {
    if (_telemetryRepository == null || index >= tabItems.length) {
      return;
    }
    if (_lastSectionViewedIndex == index) {
      return;
    }
    if (_activeSectionIndex != null && _activeSectionIndex != index) {
      _finishSectionTimedEvent();
    }
    _lastSectionViewedIndex = index;
    final title = tabItems[index].title;
    unawaited(_startSectionTimedEvent(index, title));
  }

  Future<void> _startSectionTimedEvent(int index, String title) async {
    final telemetry = _telemetryRepository;
    if (telemetry == null) {
      return;
    }
    _activeSectionTimedEventFuture = telemetry.startTimedEvent(
      EventTrackerEvents.viewContent,
      eventName: telemetryRepoString('section_viewed'),
      properties: telemetryRepoMap({
        'section_title': title,
        'position_index': index,
      }),
    );
    _activeSectionIndex = index;
  }

  void _finishSectionTimedEvent() {
    final telemetry = _telemetryRepository;
    final handleFuture = _activeSectionTimedEventFuture;
    if (telemetry == null || handleFuture == null) {
      return;
    }
    _activeSectionTimedEventFuture = null;
    _activeSectionIndex = null;
    unawaited(
      handleFuture.then<void>((handle) async {
        if (handle != null) {
          await telemetry.finishTimedEvent(handle);
        }
      }),
    );
  }
}
