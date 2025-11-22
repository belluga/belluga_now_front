import 'package:flutter/material.dart';
import 'package:value_object_pattern/value_object.dart';

class ColorRequiredValue extends ValueObject<Color> {
  ColorRequiredValue({
    super.defaultValue = Colors.transparent,
    super.isRequired = true,
  });

  @override
  Color doParse(dynamic value) {
    if (value is Color) {
      return value;
    }
    return defaultValue;
  }
}
