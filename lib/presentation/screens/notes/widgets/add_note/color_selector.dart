import 'package:flutter/material.dart';
import 'package:unifast_portal/presentation/screens/notes/widgets/color_choice.dart';

class ColorSelector extends StatelessWidget {
  final Color? selectedColor;
  final List<Color> colorOptions;

  const ColorSelector({
    super.key,
    required this.colorOptions,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8.0,
      children: List.generate(colorOptions.length, (index) {
        final color = colorOptions[index];
        return ColorChoice(
          color: color,
          isSelected: selectedColor == color,
          onTap: () {
            // Handle color selection
          },
        );
      }),
    );
  }
}
