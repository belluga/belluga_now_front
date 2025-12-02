import 'package:belluga_now/application/functions/today.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/controllers/schedule_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'date_item.dart';

class DateRow extends StatefulWidget {
  const DateRow({super.key}) : controller = null;

  @visibleForTesting
  const DateRow.withController(this.controller, {super.key});

  final ScheduleScreenController? controller;

  @override
  State<DateRow> createState() => _DateRowState();
}

class _DateRowState extends State<DateRow> {
  static const double _itemWidth = 70.0;
  static const double _itemPadding = 8.0;
  static const double _totalItemWidth = _itemWidth + (_itemPadding * 2);

  ScheduleScreenController get _controller =>
      widget.controller ?? GetIt.I.get<ScheduleScreenController>();

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<ScheduleSummaryModel?>(
        streamValue: _controller.scheduleSummaryStreamValue,
        onNullWidget: const SizedBox.shrink(),
        builder: (context, scheduleSummary) {
          if (scheduleSummary == null) {
            return const SizedBox.shrink();
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _navigateToToday();
            }
          });

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamValueBuilder<DateTime>(
                            streamValue: _controller.firsVisibleDateStreamValue,
                            builder: (context, firstDate) {
                              final minDate = _controller.firstDayRange;
                              final bool canGoBack = firstDate.isAfter(minDate);

                              return IconButton(
                                  onPressed: canGoBack
                                      ? _navigateToPreviousMonth
                                      : null,
                                  iconSize: 16,
                                  icon: const Icon(Icons.arrow_back_ios));
                            }),
                        Flexible(
                          child: StreamValueBuilder<DateTime>(
                              streamValue:
                                  _controller.firsVisibleDateStreamValue,
                              builder: (context, firstDate) {
                                final currentVisibleMonth =
                                    DateFormat.MMMM().format(firstDate);
                                final capitalizedMonth =
                                    currentVisibleMonth[0].toUpperCase() +
                                        currentVisibleMonth.substring(1);
                                return InkWell(
                                  onTap: _jumpToToday,
                                  child: Text(
                                    capitalizedMonth,
                                    textAlign: TextAlign.center,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                );
                              }),
                        ),
                        StreamValueBuilder<DateTime>(
                            streamValue: _controller.firsVisibleDateStreamValue,
                            builder: (context, firstDate) {
                              final maxDate = _controller.lastDayRange;
                              final bool canGoForward =
                                  firstDate.isBefore(maxDate);

                              return IconButton(
                                  onPressed: canGoForward
                                      ? _navigateToNextMonth
                                      : null,
                                  iconSize: 16,
                                  icon: const Icon(Icons.arrow_forward_ios));
                            }),
                      ],
                    ),
                    StreamValueBuilder<bool>(
                        streamValue: _controller.isTodayVisible,
                        builder: (context, isTodayVisible) {
                          if (isTodayVisible) {
                            return const SizedBox.shrink();
                          }

                          return ElevatedButton.icon(
                            onPressed: _navigateToToday,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onSecondary,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            ),
                            label: Text(
                              'Hoje',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                  ),
                            ),
                            icon: const Icon(
                              Icons.calendar_today,
                              size: 12,
                            ),
                          );
                        }),
                  ],
                ),
              ),
              Container(
                height: 120,
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                          itemCount: _controller.totalItems,
                          scrollDirection: Axis.horizontal,
                          controller: _controller.scrollController,
                          itemBuilder: (context, index) {
                            final DateTime date =
                                _controller.getDateByIndex(index);

                            return VisibilityDetector(
                              key: Key('date_item_$index'),
                              onVisibilityChanged: (visibilityInfo) {
                                final visibleFraction =
                                    visibilityInfo.visibleFraction;
                                if (mounted) {
                                  if (visibleFraction > 0.0) {
                                    _controller.becomeVisible(date);
                                  } else {
                                    _controller.becomeInvisible(date);
                                  }
                                }
                              },
                              child: StreamValueBuilder<DateTime>(
                                  streamValue:
                                      _controller.selectedDateStreamValue,
                                  builder: (context, asyncSnapshot) {
                                    return DateItem(
                                      date: date,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      onTap: _controller.selectDate,
                                      isSelected: _controller.isSameDay(
                                        date,
                                        _controller
                                            .selectedDateStreamValue.value,
                                      ),
                                    );
                                  }),
                            );
                          }),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }

  void _jumpToToday() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerOffset = (screenWidth / 2) - (_totalItemWidth / 2);
    final scrollTo =
        (_controller.initialIndex * _totalItemWidth) - centerOffset;
    _controller.scrollController.jumpTo(scrollTo);

    _controller.selectDate(Today.today);
  }

  void _navigateToToday() {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerOffset = (screenWidth / 2) - (_totalItemWidth / 2);
    final scrollTo =
        (_controller.initialIndex * _totalItemWidth) - centerOffset;
    _controller.scrollController.animateTo(
      scrollTo,
      duration: const Duration(milliseconds: 300),
      curve: Curves.bounceIn,
    );

    _controller.selectDate(Today.today);
  }

  void _navigateToPreviousMonth() {
    final referenceDate = _controller.firsVisibleDateStreamValue.value;
    final tentativeTarget =
        DateTime(referenceDate.year, referenceDate.month - 1, 1);
    final minDate = _controller.firstDayRange;
    final target =
        tentativeTarget.isBefore(minDate) ? minDate : tentativeTarget;

    _animateToDate(target);
  }

  void _navigateToNextMonth() {
    final referenceDate = _controller.firsVisibleDateStreamValue.value;
    final tentativeTarget =
        DateTime(referenceDate.year, referenceDate.month + 1, 1);
    final maxDate = _controller.lastDayRange;
    final target = tentativeTarget.isAfter(maxDate) ? maxDate : tentativeTarget;

    _animateToDate(target);
  }

  void _animateToDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final int index = _controller.getIndexByDate(normalized);
    final double offset = index * _totalItemWidth;

    _controller.scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    _controller.selectDate(normalized);
  }
}
