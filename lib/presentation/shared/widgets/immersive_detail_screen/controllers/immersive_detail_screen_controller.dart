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
  })  : _telemetryRepository = telemetryRepository ??
            (GetIt.I.isRegistered<TelemetryRepositoryContract>()
                ? GetIt.I.get<TelemetryRepositoryContract>()
                : null),
        scrollController = ScrollController(),
        currentTabIndexStreamValue =
            StreamValue<int>(defaultValue: initialTabIndex);

  final TelemetryRepositoryContract? _telemetryRepository;
  late final ScrollController scrollController;
  List<ImmersiveTabItem> tabItems;

  late final StreamValue<int> currentTabIndexStreamValue;

  final GlobalKey<NestedScrollViewState> nestedScrollViewKey =
      GlobalKey<NestedScrollViewState>();

  bool _isProgrammaticScroll = false;
  int? _lastSectionViewedIndex;
  Future<EventTrackerTimedEventHandle?>? _activeSectionTimedEventFuture;
  int? _activeSectionIndex;
  double _pinnedHeaderHeight = 0;

  // Track visibility of each tab
  final Map<int, double> _tabVisibility = {};

  void updateTabs(List<ImmersiveTabItem> updatedTabs) {
    tabItems = updatedTabs;
    _tabVisibility.removeWhere((index, _) => index >= tabItems.length);
    _lastSectionViewedIndex = null;

    if (tabItems.isEmpty) {
      _setCurrentTabIndex(0, track: false);
      return;
    }

    if (currentTabIndexStreamValue.value >= tabItems.length) {
      _setCurrentTabIndex(tabItems.length - 1, track: false);
    }
  }

  void updatePinnedHeaderHeight(double value) {
    _pinnedHeaderHeight = value < 0 ? 0 : value;
  }

  void onTabVisibilityChanged(int index, double visibleFraction) {
    if (index >= tabItems.length) return;

    // Don't auto-switch during programmatic scrolling
    if (_isProgrammaticScroll) return;

    _tabVisibility[index] = visibleFraction;

    // Find the tab with highest visibility that's >25%
    int? mostVisibleTab;
    double highestVisibility = 0.25; // Minimum threshold

    _tabVisibility.forEach((tabIndex, visibility) {
      if (visibility > highestVisibility) {
        highestVisibility = visibility;
        mostVisibleTab = tabIndex;
      }
    });

    // Switch to the most visible tab if it's different from current
    if (mostVisibleTab != null &&
        mostVisibleTab != currentTabIndexStreamValue.value) {
      _setCurrentTabIndex(mostVisibleTab!, track: true);
    }
  }

  void onTabTapped(int index) {
    if (index >= tabItems.length) return;

    _tabVisibility
      ..clear()
      ..[index] = 1.0;
    _setCurrentTabIndex(index, track: true);

    final nestedState = nestedScrollViewKey.currentState;
    if (nestedState == null) return;

    // Set flag to prevent auto tab switching during programmatic scroll
    _isProgrammaticScroll = true;

    Future<void>(() async {
      try {
        if (index == 0) {
          final innerPosition = nestedState.innerController.position;
          if (innerPosition.pixels > 0) {
            await nestedState.innerController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }

          final outerPosition = nestedState.outerController.position;
          if (outerPosition.pixels > 0) {
            await nestedState.outerController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }

          return;
        }

        double targetScroll = 0;
        for (int i = 0; i < index; i++) {
          final renderBox =
              tabItems[i].key.currentContext?.findRenderObject() as RenderBox?;
          targetScroll += renderBox?.size.height ?? 0;
        }
        targetScroll = (targetScroll - _pinnedHeaderHeight).clamp(
          0.0,
          double.infinity,
        );

        final outerPosition = nestedState.outerController.position;
        final collapsedHeaderOffset = outerPosition.maxScrollExtent;
        if ((outerPosition.pixels - collapsedHeaderOffset).abs() > 0.5) {
          await nestedState.outerController.animateTo(
            collapsedHeaderOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }

        await nestedState.innerController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } finally {
        _isProgrammaticScroll = false;
      }
    });
  }

  void onHorizontalSwipeEnd(double? primaryVelocity) {
    if (primaryVelocity == null || primaryVelocity.abs() < 300) {
      return;
    }
    if (tabItems.length < 2) {
      return;
    }

    final delta = primaryVelocity < 0 ? 1 : -1;
    final targetIndex = (currentTabIndexStreamValue.value + delta)
        .clamp(0, tabItems.length - 1);
    if (targetIndex == currentTabIndexStreamValue.value) {
      return;
    }
    onTabTapped(targetIndex);
  }

  void dispose() {
    _finishSectionTimedEvent();
    scrollController.dispose();
    currentTabIndexStreamValue.dispose();
  }

  void _setCurrentTabIndex(int index, {required bool track}) {
    currentTabIndexStreamValue.addValue(index);
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
    unawaited(handleFuture.then<void>((handle) async {
      if (handle != null) {
        await telemetry.finishTimedEvent(handle);
      }
    }));
  }
}
