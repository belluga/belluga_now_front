import 'package:flutter/material.dart';

class ImmersiveTabBar extends StatelessWidget {
  const ImmersiveTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabTapped,
    super.key,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.64);
    final textStyle = theme.textTheme.labelLarge;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Semantics(
            container: true,
            label: tabs[index],
            button: true,
            selected: isSelected,
            onTap: () => onTabTapped(index),
            child: InkWell(
              key: Key('immersiveTab_$index'),
              excludeFromSemantics: true,
              onTap: () => onTabTapped(index),
              child: ExcludeSemantics(
                child: Container(
                  key: Key(
                    isSelected
                        ? 'immersiveTabSelected_$index'
                        : 'immersiveTabUnselected_$index',
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? selectedColor : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    key: Key('immersiveTabLabel_$index'),
                    tabs[index],
                    style: TextStyle(
                      color: isSelected ? selectedColor : unselectedColor,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ).merge(textStyle),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
