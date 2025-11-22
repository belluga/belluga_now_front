import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/controllers/schedule_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class DateItem extends StatefulWidget {
  const DateItem({
    super.key,
    required this.date,
    required this.onTap,
    this.isSelected = false,
    this.padding,
    this.width = 70,
  }) : controller = null;

  @visibleForTesting
  const DateItem.withController(
    this.controller, {
    super.key,
    required this.date,
    required this.onTap,
    this.isSelected = false,
    this.padding,
    this.width = 70,
  });

  final DateTime date;
  final bool isSelected;
  final double width;
  final EdgeInsets? padding;
  final void Function(DateTime) onTap;
  final ScheduleScreenController? controller;

  @override
  State<DateItem> createState() => _DateItemState();
}

class _DateItemState extends State<DateItem> {
  ScheduleScreenController get _controller =>
      widget.controller ?? GetIt.I.get<ScheduleScreenController>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dayTextColor = widget.isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final borderColor =
        _isToday() ? colorScheme.primaryContainer : Colors.transparent;
    final backgroundColor =
        widget.isSelected ? colorScheme.primaryContainer : Colors.transparent;

    return InkWell(
      onTap: _selectDate,
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: widget.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                DateFormat('E')
                    .format(widget.date)
                    .substring(0, 1)
                    .toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: backgroundColor,
                  radius: 18,
                  child: Text(
                    widget.date.day.toString(),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: dayTextColor),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 50,
                child: StreamValueBuilder<List<dynamic>>(
                  streamValue: _controller.allEventsStreamValue,
                  builder: (context, _) {
                    final confirmedCount =
                        _controller.getConfirmedEventsCountByDate(widget.date);
                    final pendingCount =
                        _controller.getPendingInvitesCountByDate(widget.date);

                    if (confirmedCount == 0 && pendingCount == 0) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Confirmed events markers (green)
                        if (confirmedCount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              confirmedCount.clamp(0, 3),
                              (_) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 1.5),
                                child: CircleAvatar(
                                  radius: 3,
                                  backgroundColor: Colors.green.shade600,
                                ),
                              ),
                            ),
                          ),
                        if (confirmedCount > 0 && pendingCount > 0)
                          const SizedBox(height: 2),
                        // Pending invites markers (orange)
                        if (pendingCount > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              pendingCount.clamp(0, 3),
                              (_) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 1.5),
                                child: CircleAvatar(
                                  radius: 3,
                                  backgroundColor: Colors.orange.shade600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday() {
    final now = DateTime.now();
    return now.year == widget.date.year &&
        now.month == widget.date.month &&
        now.day == widget.date.day;
  }

  void _selectDate() {
    widget.onTap(widget.date);
  }
}
