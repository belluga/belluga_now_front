import 'package:flutter/material.dart';

class AnimatedTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AnimatedTabAppBar({super.key, this.appBar});

  final PreferredSizeWidget? appBar;

  @override
  Size get preferredSize =>
      Size.fromHeight(appBar?.preferredSize.height ?? kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: child,
      ),
      child: appBar ?? const SizedBox.shrink(),
    );
  }
}
