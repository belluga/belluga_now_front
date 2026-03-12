import 'package:push_handler/push_handler.dart';

class PushOptionSelectorPayload {
  const PushOptionSelectorPayload({
    required this.title,
    required this.body,
    required this.layout,
    required this.gridColumns,
    required this.selectionMode,
    required this.options,
    required this.minSelected,
    required this.maxSelected,
    required this.initialSelected,
  });

  final String title;
  final String body;
  final String layout;
  final int gridColumns;
  final String selectionMode;
  final List<OptionItem> options;
  final int minSelected;
  final int maxSelected;
  final List<dynamic> initialSelected;
}
