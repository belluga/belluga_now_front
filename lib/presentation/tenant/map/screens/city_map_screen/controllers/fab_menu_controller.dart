import 'package:get_it/get_it.dart' show Disposable;
import 'package:stream_value/core/stream_value.dart';

enum LateralPanelType { regions, events, music, cuisines }

class FabMenuController implements Disposable {
  FabMenuController()
      : menuExpanded = StreamValue<bool>(defaultValue: false),
        activePanel = StreamValue<LateralPanelType?>();

  final StreamValue<bool> menuExpanded;
  final StreamValue<LateralPanelType?> activePanel;

  void toggleMenu() {
    final expanded = menuExpanded.value;
    menuExpanded.addValue(!expanded);
  }

  void openPanel(LateralPanelType type) {
    if (activePanel.value == type) {
      closePanel();
      return;
    }
    activePanel.addValue(type);
    menuExpanded.addValue(false);
  }

  void closePanel() {
    activePanel.addValue(null);
    menuExpanded.addValue(false);
  }

  bool get isPanelOpen => activePanel.value != null;

  @override
  void onDispose() {
    menuExpanded.dispose();
    activePanel.dispose();
  }
}
