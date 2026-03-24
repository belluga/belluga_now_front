typedef ScheduleSummaryItemModelPrimString = String;
typedef ScheduleSummaryItemModelPrimInt = int;
typedef ScheduleSummaryItemModelPrimBool = bool;
typedef ScheduleSummaryItemModelPrimDouble = double;
typedef ScheduleSummaryItemModelPrimDateTime = DateTime;
typedef ScheduleSummaryItemModelPrimDynamic = dynamic;

class ScheduleSummaryItemModel {
  final ScheduleSummaryItemModelPrimString? color;
  final ScheduleSummaryItemModelPrimDateTime dateTimeStart;

  ScheduleSummaryItemModel({
    this.color,
    required this.dateTimeStart,
  });
}
