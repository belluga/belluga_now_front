import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:flutter/widgets.dart';

class ImmersiveCommonTabs {
  const ImmersiveCommonTabs._();

  static const String aboutTitle = 'Sobre';
  static const String directionsTitle = 'Como Chegar';

  static ImmersiveTabItem about({
    required Widget content,
    Widget? footer,
  }) {
    return ImmersiveTabItem(
      title: aboutTitle,
      content: content,
      footer: footer,
    );
  }

  static ImmersiveTabItem directions({
    required Widget content,
    Widget? footer,
  }) {
    return ImmersiveTabItem(
      title: directionsTitle,
      content: content,
      footer: footer,
    );
  }

  static ImmersiveTabItem custom({
    required String title,
    required Widget content,
    Widget? footer,
    ImmersiveTabHorizontalSwipeHandler? onHorizontalSwipeEnd,
  }) {
    return ImmersiveTabItem(
      title: title,
      content: content,
      footer: footer,
      onHorizontalSwipeEnd: onHorizontalSwipeEnd,
    );
  }
}
