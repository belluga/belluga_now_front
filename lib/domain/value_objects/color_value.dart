import 'package:flutter/material.dart';
import 'package:value_object_pattern/value_object.dart';

class ColorValue extends ValueObject<Color> {
  ColorValue({
    required super.defaultValue,
    super.isRequired = true,
  });

  @override
  Color doParse(String? parseValue) {
    String formattedHex =
        parseValue!.startsWith('#') ? parseValue : '#$parseValue';

    // 2. Add the alpha channel (FF for opaque) if it's missing.
    // Handles formats like #RGB, #RRGGBB
    if (formattedHex.length == 4) {
      // #RGB
      final r = formattedHex[1];
      final g = formattedHex[2];
      final b = formattedHex[3];
      formattedHex = '#FF$r$r$g$g$b$b';
    } else if (formattedHex.length == 7) {
      // #RRGGBB
      formattedHex = '#FF${formattedHex.substring(1)}';
    }

    // 3. Parse the hex string to an integer and create the Color.
    // The string must be a valid 32-bit hex value (e.g., '0xAARRGGBB').
    // The 'radix: 16' specifies that we are parsing a hexadecimal number.
    return Color(int.parse(formattedHex.substring(1), radix: 16));
  }
}
