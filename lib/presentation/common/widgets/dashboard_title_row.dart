import 'package:flutter/material.dart';

class DashboardTitleRow extends StatefulWidget {
  final String title;
  final String? showAllLabel;
  final Function()? onShowAllPressed;

  const DashboardTitleRow({
    super.key,
    required this.title,
    this.showAllLabel,
    this.onShowAllPressed,
  });

  @override
  State<DashboardTitleRow> createState() => _DashboardTitleRowState();
}

class _DashboardTitleRowState extends State<DashboardTitleRow> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 56.0),
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, top: 8.0, right: 16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (widget.showAllLabel != null)
              ElevatedButton(
                onPressed: widget.onShowAllPressed ?? () {},
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                  padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                    EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  ),
                ),
                child: Text(
                  widget.showAllLabel ?? "",
                  style: TextTheme.of(context).labelSmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
