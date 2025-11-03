import 'package:stream_value/core/stream_value.dart';

enum FabMenuAction { none, regions, events, music, cuisines }

class FabMenuController {
  FabMenuController();

  final StreamValue<bool> menuExpanded =
      StreamValue<bool>(defaultValue: false);
  final StreamValue<FabMenuAction> activePanel =
      StreamValue<FabMenuAction>(defaultValue: FabMenuAction.none);

  void toggleMenu() {
    final current = menuExpanded.value ?? false;
    menuExpanded.addValue(!current);
  }

  void closeMenu() {
    menuExpanded.addValue(false);
  }

  void openPanel(FabMenuAction action) {
    activePanel.addValue(action);
    menuExpanded.addValue(false);
  }

  void closePanel() {
    activePanel.addValue(FabMenuAction.none);
  }

  bool get isMenuExpanded => menuExpanded.value ?? false;
  FabMenuAction get selectedPanel => activePanel.value;

  void dispose() {
    menuExpanded.dispose();
    activePanel.dispose();
  }
}
