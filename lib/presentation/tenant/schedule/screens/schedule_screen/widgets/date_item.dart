import 'package:belluga_now/presentation/tenant/schedule/screens/schedule_screen/controllers/schedule_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class DateItem extends StatefulWidget {
  const DateItem({
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

  @override
  State<DateItem> createState() => _DateItemState();
}

class _DateItemState extends State<DateItem> {
  final _controller = GetIt.I.get<ScheduleScreenController>();

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

    final eventItems = _controller.getEventsSummaryByDate(widget.date);

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
                width: 40,
                child: eventItems.isEmpty
                    ? const SizedBox.shrink()
                    : Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        alignment: WrapAlignment.center,
                        children: eventItems
                            .map(
                              (_) => CircleAvatar(
                                radius: 3,
                                backgroundColor: colorScheme.secondary,
                              ),
                            )
                            .toList(),
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
