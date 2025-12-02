import 'package:flutter/material.dart';
import 'package:value_object_pattern/value_object.dart';

class BrightnessValue extends ValueObject<Brightness> {
  BrightnessValue({
    super.defaultValue = Brightness.light,
    super.isRequired = false,
  });

  @override
  Brightness doParse(dynamic value) {
    if (value is String) {
      if (value == 'dark') {
        return Brightness.dark;
      } else {
        return Brightness.light;
      }
    }
    return defaultValue;
  }
}
