import 'package:flutter/material.dart';

class CalendarBox extends StatefulWidget {
  final String month;
  final int day;

  const CalendarBox({super.key, required this.month, required this.day});

  @override
  State<CalendarBox> createState() => _CalendarBoxState();
}

class _CalendarBoxState extends State<CalendarBox> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Text(
              widget.month.toUpperCase().substring(0, 3),
              textAlign: TextAlign.center,
              style: TextTheme.of(context).labelLarge,
            ),
          ),
          Container(
            // padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text(
              widget.day.toString(),
              textAlign: TextAlign.center,
              style: TextTheme.of(context).titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
