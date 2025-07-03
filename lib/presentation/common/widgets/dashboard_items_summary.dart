import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/common/widgets/dashboard_title_row.dart';

class DashboardItemsSummary extends StatefulWidget {
  final String title;
  final String? showAllLabel;
  final Function()? onShowAllPressed;
  final double itemsPerRow;
  final Widget? Function(BuildContext, int)? itemsBuilder;
  final double itemHeight;

  const DashboardItemsSummary({
    super.key,
    required this.title,
    this.itemsBuilder,
    this.showAllLabel,
    this.onShowAllPressed,
    this.itemsPerRow = 2.3,
    this.itemHeight = 100,
  });

  @override
  State<DashboardItemsSummary> createState() => _DashboardItemsSummaryState();
}

class _DashboardItemsSummaryState extends State<DashboardItemsSummary> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardTitleRow(
                title: widget.title,
                showAllLabel: widget.showAllLabel,
                onShowAllPressed: widget.onShowAllPressed,
              ),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: widget.itemHeight,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 16.0, right: 16),
                        scrollDirection: Axis.horizontal,
                        itemExtent: _itemExtentCalculation(),
                        itemBuilder: widget.itemsBuilder ?? _mockItemBuilder,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _itemExtentCalculation() {
    final double _widthSize = MediaQuery.of(context).size.width;

    return _widthSize / (widget.itemsPerRow);
  }

  Widget? _mockItemBuilder(BuildContext context, int index) {
    if (index >= 10) {
      return null;
    }

    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceDim,
      child: SizedBox(
        height: 120,
        child: Center(child: Text("Item ${index + 1}")),
      ),
    );
  }
}
